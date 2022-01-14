package Telebot;
use Mojo::Base 'Mojolicious', -signatures;

sub startup ($self) {
    $self->pre_startup;

    $self->moniker('telebot');
    push @{$self->plugins->namespaces}, 'Telebot::Plugin';
    push @{$self->renderer->classes}, 'Telebot';
    push @{$self->routes->namespaces}, 'Telebot::Controller';
    
    my $config = $self->plugin('Config');
    $self->mode($config->{mode} || 'development');
    
    if (-e $self->home . '/logs') {
        $self->log(Mojo::Log->new(
            path => $self->home . '/logs/' . $self->mode . '.log',
        ));
    }

    $self->secrets($config->{secrets});
    
    $self->plugin('Utils');
    $self->plugin('DB');
    $self->plugin(Minion => {Pg => $config->{connection}});
    $self->plugin('Minion::Admin');    
    $self->plugin('Telegram');
    $self->plugin('Telegram::UI');
    $self->plugin('Hooks');

    my $r = $self->routes;
    $r->get('/')->to('tg#index');

    $self->post_startup();
}
sub pre_startup ($self) {$self}
sub post_startup ($self) {$self}

1;

__DATA__

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>

@@ tg/index.html.ep
% layout 'default';
% title 'tgbot';
<p>Telegram bot</p>
