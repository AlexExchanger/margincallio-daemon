Daemon
======

This part is responsible for clients notifications and DB writing of all Orders and Deals

Installation:

- Follow http://elixir-lang.org/install.html

- mix deps.get

- iex -S mix run (for simple running, for production please use any of elixir release tools)

- localhost:8000 Presenting a simple page where all notifications are sent to dev console)

- Specifications of all messages are presented in a .docx file. All messages are presented, but in general instruction is written in Russian. Translation is in progress.

- IP address and port of core connection is harcodec in lib/daemon.ex on line 44 :-)

- DB setting are presented in  /config/config.exs file

Todolist:

- add users autentification (now everybody can subscribe on everybody's channel)
