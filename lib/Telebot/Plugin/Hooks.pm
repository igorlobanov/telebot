package Telebot::Plugin::Hooks;
use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Carp 'croak';
use Mojo::Util qw(dumper);

use strict;

has ['app'];

sub register {
    my ($self, $app, $config) = @_;

    $self->app($app);

    $app->hook(before_render => sub ($c, $args) {
        return unless my $template = $args->{template};
        return unless $c->accepts('json');
        return unless $template =~ /^exception(\.(development|production))?$/;
        $args->{json} = {code => 500, message => $c->config->{mode} eq 'production' ? 'Internal server error' : $c->stash('exception')};
    });

    $app->hook(before_dispatch => sub {
        my $c = shift;
        $c->req->url->base->scheme($c->req->headers->header('X-Forwarded-Proto'))
            if $c->req->headers->header('X-Forwarded-Proto');
    });

    # Hook to start Minion together with server up
    $app->hook(before_server_start => sub {
      my ($server, $app) = @_;
      
      # setup setWebhook
      my $token = $app->tg->gentoken;
      my $set = $app->tg->request(setWebhook => {
          url => $app->config->{self_url}.'/'.$token,
          allowed_updates => $app->tg->allowed_updates,
      });
      if (!$set->{ok}) {
          $app->log->info('Webhook setup error', $set->{description});
          die "Webhook setup error\n";
      }
      else {
          $app->routes->any('/'.$token)->to('tg#update');
          $app->log->info('Webhook set to /'.$token);
      }

      $server->on(spawn => sub {
        my ($server, $pid) = @_;
        my $worker = $app->minion->worker;
        $worker->status({parent => $pid});
        my $subprocess = Mojo::IOLoop::Subprocess->new;
        $subprocess->run(
          sub { $worker->run },
          sub ($subprocess, $err, @results) { $app->log->info($err) }
        );
        $subprocess->on(spawn => sub {
          my ($subprocess) = @_;
          $app->log->info("Minion worker " . $subprocess->pid . " started");
        });
      });
      
      $server->on(reap => sub {
        my ($server, $pid) = @_;
        my $workers = $app->minion->workers;
        while (my $info = $workers->next) {
          if ($info->{status}{parent}==$pid) {
            $app->log->info("Minion worker $info->{pid} stopped");
            kill TERM => $info->{pid};
          }
        }
      });

    });
}

1;

__DATA__
