# NAME

Telebot - Mojolicious-based Telegram bot

# SYNOPSIS

    # Create telebot application
    
    telebot bot generate My::Bot
    

# DESCRIPTION

This library helps to create mojolicious based Telegram
bots. Application works via telegram webhooks.
It creates route and register it in telegram. Requests
form telegram are processed on this route. Application
processes requests via minion tasks to minimize web
interaction time.
You can include your application logic in so called
handlers. You have several types of handlers - one
for update and one for each possible part of update.
Handlers are located in **lib/Handler** folder and have
corresponding names:

    Update.pm
    
    CallbackQuery.pm
    ChannelPost.pm
    ChatJoinRequest.pm
    ChatMember.pm
    ChosenInlineResult.pm
    EditedChannelPost.pm
    EditedMessage.pm
    InlineQuery.pm
    Message.pm
    MyChatMember.pm
    Poll.pm
    PollAnswer.pm
    PreCheckoutQuery.pm
    ShippingQuery.pm

To implement your logic you must overwrite subroutine
**run**

    package My::Bot::Handler::Message;
    use Mojo::Base 'Telebot::Handler', -signatures;

    sub run ($self) {
        
        # Your magic here
        
        $self;
    }

    1;

Handler have attributes
**app** - reference to application,
**payload** - data recieved from update,
**update\_id** - Telegram ID of update.

Handler **Update** gets full update paypload.
Typed handlers gets only corresponding part of update.

For example if incoming update contain message -
two handlers will be executed - Update and Message.
Update will recieve full update payload, Message only
message part of update.

For interaction with Telegram API you can use helper
**tg:request**

    $self->app->tg->request(getMe => {});
    
    $self->app->tg->request(sendLocation => {
        chat_id => 777,
        latitude => 90-rand(180),
        longitude => 180-rand(360),
    });
    

# COPYRIGHT AND LICENSE

Copyright (C) 2022, Igor Lobanov.
This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

# SEE ALSO

[https://github.com/igorlobanov/telebot](https://github.com/igorlobanov/telebot), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious%3A%3AGuides), [https://mojolicious.org](https://mojolicious.org), [https://core.telegram.org/api](https://core.telegram.org/api).
