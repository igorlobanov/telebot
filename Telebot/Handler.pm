package Telebot::Handler;
use Mojo::Base -base, -signatures;
has [qw(app payload update_id)] => undef, weak => 1;

sub run ($self) {
    $self->app->dump($self->payload);
} 

1;
