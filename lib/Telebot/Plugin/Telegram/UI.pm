package Telebot::Plugin::Telegram::UI;

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Mojo::UserAgent;
use Carp 'croak';
use Mojo::Util qw(camelize);
use Mojo::Collection qw(c);
use Mojo::JSON qw(to_json);
use Scalar::Util qw(blessed);
use Mojo::Loader qw(load_class load_classes);

has ['app'] => undef;

sub register {
    my ($self, $app, $config) = @_;

    $self->app($app);
    
    # $app->tg->ui->input(
    #     chat_id => 1,
    #     [text => 'Field instruction',]
    #     [placeholder => 'Hint text (<=64 symbols)',]
    # );
    $app->helper('tg.ui.input' => sub ($c, @args) {
        my $options = _args(@args);
        return {
            ok => 0,
            description => 'tg->ui->input: No chat_id',
        } if !$options->{chat_id};
        $c->tg->request(sendMessage => {
            chat_id => $options->{chat_id},
            text => $options->{text} // 'Input field',
            reply_markup => {
                force_reply => \1,
                input_field_placeholder => $options->{placeholder} || '',
            },
        });
        # save message_id for input field
    });
    # $app->tg->ui->choice(
    #     chat_id => 1,
    #     [text => 'Choice instruction',]
    #     buttons => [
    #         [ #Row1
    #             {
    #                 text => 'Button1',
    #                 callback_data => 'btn1',
    #             },
    #             {
    #                 text => 'Button2',
    #                 callback_data => 'btn2',
    #             },
    #         ],
    #         [ #Row2
    #             {
    #                 text => 'Button3',
    #                 callback_data => 'btn3',
    #             },
    #             {
    #                 text => 'Button4',
    #                 callback_data => 'btn4',
    #             },
    #         ]
    #     ],
    # );
    $app->helper('tg.ui.choice' => sub ($c, @args) {
        my $options = _args(@args);
        return {
            ok => 0,
            description => 'tg->ui->choice: No chat_id',
        } if !$options->{chat_id};
        return {
            ok => 0,
            description => 'tg->ui->choice: No buttons',
        } if !@{$options->{buttons}||[]};
        $c->tg->request(sendMessage => {
            chat_id => $options->{chat_id},
            text => $options->{text} // 'Select',
            reply_markup => {
                inline_keyboard => [map {
                    [map {$_} @$_]
                } @{$options->{buttons}||[]}],
                #resize_keyboard => \1,
                #one_time_keyboard => \1,
            },
        });
    });
    # $app->tg->ui->menu(
    #     chat_id => 1,
    #     [text => 'Menu instruction',]
    #     buttons => [
    #         [ #Row1
    #             {
    #                 text => 'Button1',
    #                 callback_data => 'btn1',
    #             },
    #             {
    #                 text => 'Button2',
    #                 callback_data => 'btn2',
    #             },
    #         ],
    #         [ #Row2
    #             {
    #                 text => 'Button3',
    #                 callback_data => 'btn3',
    #             },
    #             {
    #                 text => 'Button4',
    #                 callback_data => 'btn4',
    #             },
    #         ]
    #     ],
    # );
    $app->helper('tg.ui.menu' => sub ($c, @args) {
        my $options = _args(@args);
        return {
            ok => 0,
            description => 'tg->ui->menu: No chat_id',
        } if !$options->{chat_id};
        return {
            ok => 0,
            description => 'tg->ui->menu: No buttons',
        } if !@{$options->{buttons}||[]};
        $c->tg->request(sendMessage => {
            chat_id => $options->{chat_id},
            text => $options->{text} // 'Select',
            reply_markup => {
                inline_keyboard => [map {
                    [map {$_} @$_]
                } @{$options->{buttons}||[]}],
                resize_keyboard => \1,
                one_time_keyboard => \1,
            },
        });
    });
    # $app->tg->ui->error(
    #     chat_id => 1,
    #     [text => 'Error text',]
    #     [reply_to => 1,]
    # );
    $app->helper('tg.ui.error' => sub ($c, @args) {
        my $options = _args(@args);
        return {
            ok => 0,
            description => 'tg->ui->error: No chat_id',
        } if !$options->{chat_id};
        $c->tg->request(sendMessage => {
            chat_id => $options->{chat_id},
            text => $options->{text} || 'Error',
            ($options->{reply_to} ? (reply_to_message_id => $options->{reply_to}) : ())
        });
    });
    
}

sub _args {
    ~~@_%2==0 ? {@_} : $_[0];
}

1;

__DATA__
