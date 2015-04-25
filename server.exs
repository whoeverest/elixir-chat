defmodule Chat do
    def init do
        {:ok, socket} = :gen_tcp.listen(8333, [:binary, packet: :line, active: false])
        b_pid = spawn fn -> broadcaster_loop [] end
        acceptor_loop(b_pid, socket)
    end

    def acceptor_loop(b_pid, socket) do
        {:ok, client_socket} = :gen_tcp.accept socket
        send b_pid, { :new_client, client_socket }
        spawn fn -> client_loop b_pid, client_socket end
        acceptor_loop(b_pid, socket)
    end

    def send_all(clients, msg) do
        Enum.each clients, fn c -> :gen_tcp.send c, msg end
    end

    def handle_new_client(clients) do
        send_all clients, "new client joined\n"
    end

    def broadcaster_loop(clients) do
        receive do
            {:new_client, client} ->
                handle_new_client clients
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
end

Chat.init()