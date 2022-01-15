package Telebot::Plugin::Utils;
use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Carp 'croak';
use Mojo::Util qw(dumper);

use strict;

has ['app'];

sub register {
    my ($self, $app, $config) = @_;

    $self->app($app);

    # $app->dump($var1, $var2, ...)
    $app->helper(dump => sub {
      my $c = shift;
      $app->log->info(dumper([@_]));
    });
    $self;
}

1;

__DATA__
