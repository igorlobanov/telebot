package Telebot::Task::Update;
use Mojo::Base 'Minion::Job', -signatures;

sub run ($job, $payload) {
    my $app = $job->app;
    if ($payload->{update_id}) {
        if (my $handler = $app->tg->handler('update')) {
            $handler->new(
                app => $app,
                update_id => $payload->{update_id},
                payload => $payload,
            )->run;
        }
        for ($app->tg->allowed_updates->each) {
            $app->minion->enqueue($_ => [
                $payload->{$_},
                $payload->{update_id}
            ]) if exists $payload->{$_};
        }
    }
    else {
        $job->note(warning => 'No update_id');
    }
    return $job->finish;
}

1;