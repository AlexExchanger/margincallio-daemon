defmodule TestServer do
    def start() do
        {:ok, lsock} = :gen_tcp.listen(5679, [:binary, {:packet, 2}, {:active, :false}])
        test_accept(lsock)
    end
    def test_accept(lsock) do
        {:ok, sock} = :gen_tcp.accept(lsock)
        test_send(sock)
        :ok = :gen_tcp.close(sock)
        test_accept(lsock)
    end
    def test_send(sock) do
        msg = IO.gets("Message: ")
        IO.inspect msg
        :gen_tcp.send(sock,msg)
    end
end