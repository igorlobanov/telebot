package Telebot::Templates;
use Mojo::Base -base;
1;
__DATA__

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>

@@ tg/index.html.ep
% layout 'default';
% title 'tgbot';
<p>Telegram bot</p>
