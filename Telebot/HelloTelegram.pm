package Telebot::HelloTelegram;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;
  push @{$self->commands->namespaces}, 'Telebot::Command';
}

1;
