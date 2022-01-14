package Telebot::Task::Update::PreCheckoutQuery;
use Mojo::Base 'Minion::Job', -signatures;
 
sub run ($job, $payload, $update_id) {
    my $app = $job->app;
    return $job->finish('Completed');
}
 
1;
