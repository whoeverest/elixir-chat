defmodule Chat do
    def init do
        {:ok, socket} = :gen_tcp.listen(8333, [:binary, packet: :line, active: false])
        b_pid = spawn fn -> broadcaster_loop [] end
        acceptor_loop(b_pid, socket)
    end

    def acceptor_loop(b_pid, socket) do
        {:ok, client_socket} = :gen_tcp.accept socket
        spawn fn -> client_new b_pid, client_socket end
        acceptor_loop(b_pid, socket)
    end

    def send_all(clients, msg) do
        Enum.each clients, fn c -> :gen_tcp.send c, msg end
    end

    def handle_new_client(clients, nick) do
        send_all clients, nick <> " has joined\n"
    end

    def broadcaster_loop(clients) do
        receive do
            {:new_client, client, nick} ->
                handle_new_client clients, nick
                broadcaster_loop [client] ++ clients
            {:new_message, msg}   ->
                send_all clients, msg
                broadcaster_loop clients
        end
    end

    def client_loop(b_pid, socket) do
        {:ok, msg} = :gen_tcp.recv socket, 0
        send b_pid, {:new_message, msg}
        client_loop b_pid, socket
    end

    def nick_is_valid(nick) do
        nick != ""
    end

    def client_new(b_pid, socket) do
        :gen_tcp.send socket, "Enter your username: "
        {:ok, nick} = :gen_tcp.recv socket, 0
        nick = String.strip nick

        case nick_is_valid(nick) do
            true ->
                send b_pid, {:new_client, socket, nick}
                client_loop b_pid, socket
        end
    end
end

Chat.init()