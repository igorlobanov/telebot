package Telebot::Plugin::DB;

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Mojo::Pg;

has [qw(app connection dbh)];

sub register ($self, $app, $conf) {
    $self->app($app);
    $self->connection($conf->{connection} || $app->config->{connection});

    $app->helper('connect.dbh' => sub {
        my ($c) = @_; 
        die "Connection not found" if !$self->connection;
        if (!$self->dbh || !$self->dbh->db->ping) {
            $self->dbh(Mojo::Pg->new($self->connection));
        }
        $self->dbh;
    });
    $app->helper('connect.db' => sub {
        shift->connect->dbh->db;
    });
    $self;
}

1;
