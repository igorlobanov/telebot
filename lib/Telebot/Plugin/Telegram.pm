package Telebot::Plugin::Telegram;

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Mojo::UserAgent;
use Carp 'croak';
use Mojo::Util qw(camelize);
use Mojo::Collection qw(c);
use Mojo::JSON qw(to_json);
use Scalar::Util qw(blessed);
use Mojo::Loader qw(load_class load_classes);

has ['app', 'ua', 'config'] => undef;
has allowed_updates => sub {c(qw(
    message edited_message
    channel_post edited_channel_post
    inline_query chosen_inline_result
    callback_query shipping_query pre_checkout_query
    poll poll_answer
    my_chat_member chat_member chat_join_request
))};
has handlers => sub {{}};

sub register {
    my ($self, $app, $config) = @_;

    $self->app($app);
    $self->ua(Mojo::UserAgent->new->inactivity_timeout(0));
    $self->config($app->config->{telegram} ? $app->config->{telegram} : $config || {});
    croak 'Setup bot token in config' if !$self->config->{token};
    $self->allowed_updates(
        c(@{$self->config->{allowed_updates}})
    ) if $self->config->{allowed_updates};
    
    # Handlers
    load_classes("Telebot::Handler");
    for ($self->allowed_updates->each, 'update') {
        my $mod = "@{[ ref($app) ]}::Handler::@{[ camelize($_) ]}";
        if (my $e = load_class($mod)) {
            if (ref $e) {
                $app->log->error("Loading $mod exception: $e");
            }
            else {
                $self->handlers->{$_} = "Telebot::Handler::@{[ camelize($_) ]}";
                $app->log->info("$mod not found, Telebot::Handler::@{[ camelize($_) ]} loaded");
            }
        }
        else {
            $app->log->info("$mod loaded");
            $self->handlers->{$_} = $mod;
        }
    }

    # $app->tg->handlers()
    $app->helper('tg.handlers' => sub ($c) { $self->handlers });
    
    # $app->tg->handler('message')
    $app->helper('tg.handler' => sub ($c, $type) { $self->handlers->{$type} });
    
    # $app->tg->gentoken()
    $app->helper('tg.gentoken' => sub ($c) { _gentoken() });
    
    # $app->tg->url('getMe')
    $app->helper('tg.url' => sub ($c, $method) {
        sprintf('%s/bot%s/%s',
            $self->config->{api_server} || 'https://api.telegram.org',
            $self->config->{token},
            $method)
    });
    
    # $app->tg->request()
    $app->helper('tg.request' => sub ($c, $method, $payload) {
        $self->app->log->info("Request $method");
        my $db = $self->app->connect->db;
        my $tx = $self->ua->build_tx(
            POST => $self->app->tg->url($method),
            _prepare_payload($payload, $app),
        );
        $tx = $self->ua->start($tx);
        if ($tx->res->code == 200) {
            return $tx->res->json;
        }
        else {
            $self->app->dump($tx->res);
            return $tx->res->json || {
                ok => 0,
                description => sprintf('Error %s during request', $tx->res->code),
            };
        }
    });
    
    # $app->tg->modules
    $app->helper('tg.allowed_updates' => sub ($c) {
        $self->allowed_updates;
    });
    
    # $app->tg->extract_commands($payload)
    $app->helper('tg.extract_commands' => sub ($c, $text, $entities) {
        my @commands;
        for (grep {$_->{type} eq 'bot_command'} @{$entities||[]}) {
            my $cmd = substr($text, $_->{offset}+1, $_->{length});
            $cmd =~ /^([^@]+)@?([^@]+)?$/;
            push @commands, {
                command => $1,
                bot => $2,
            }
        }
        return c(@commands);
    });
    
    # Minion task
    $app->minion->add_task(update => 'Telebot::Task::Update');
    $app->minion->add_task($_ => 'Telebot::Task::UpdateField') for $self->allowed_updates->each;
    
}

sub _gentoken {
    join('', map {[0..9, 'a'..'z', 'A'..'Z']->[rand(62)]} (1..24))
}

sub _find_files {
    my ($var, $files) = @_;
    $files ||= {};
    if (ref $var eq 'HASH') {
        $var = {map {
            $_ => scalar _find_files($var->{$_}, $files)
        } keys %$var};
    }
    elsif (ref $var eq 'ARRAY') {
        $var = [map {
            scalar _find_files($_, $files)
        } @$var];
    }
    elsif (blessed $var && $var->isa('Mojo::Asset')) {
        my $name = _gentoken();
        $name = _gentoken() while exists $files->{$name};
        $files->{$name} = {file => $var};
        $var = "attach://$name";
    }
    return wantarray ? ($var, $files) : $var;
}

sub _prepare_payload {
    my ($payload) = @_;
    my ($data, $files) = _find_files($payload);
    if (keys %$files) {
        return (
            {'Content-Type' => 'multipart/form-data'},
            form => {
                (map {
                    $_ => ref $data->{$_} ? to_json($data->{$_}) : $data->{$_};
                } keys %$data),
                %$files,
            },
        );
    }
    else {
        return (
            {'Content-Type' => 'application/json'},
            json => $data || {},
        );
    }
}

1;

__DATA__
