package Telebot::Controller::Tg;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub update ($c) {
    my $data = $c->req->json;
    $c->dump($data) if $c->app->config->{trace};
    if ($data->{update_id}) {
        $c->minion->enqueue(update => [$data]);
    }
    $c->render(json => {ok => \1});
}

sub index ($c) {
    $c->render;
}

1;

