package Telebot::Task::UpdateField;
use Mojo::Base 'Minion::Job', -signatures;

sub run ($job, $payload, $update_id) {
    my $app = $job->app;
    my $db = $job->app->connect->db;
    if (my $handler = $app->tg->handler($job->task)) {
        $handler->new(
            app => $app,
            update_id => $update_id,
            payload => $payload,
        )->run;
    }
    else {
        $job->note(warning => 'No handler for '.$job->task);
    }
    return $job->finish;
}

1;