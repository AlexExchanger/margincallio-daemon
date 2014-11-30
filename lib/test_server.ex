defmodule TestServer do
    def start() do
        {:ok, lsock} = :gen_tcp.listen(5679, [:binary, {:packet, 2}, {:active, :false}])
        test_accept(lsock)
    end
    def test_accept(lsock) do
        {:ok, sock} = :gen_tcp.accept(lsock)
        test_send(sock,1)
        :ok = :gen_tcp.close(sock)
        test_accept(lsock)
    end
    def test_send(sock,0) do
    end
    def test_send(sock, number) do
        :gen_tcp.send(sock,"{\"type\":\"system\"}")
        #:gen_tcp.send(sock,"1")
        test_send(sock, number-1)
    end
end