from fakeredis import TcpFakeServer
TcpFakeServer(('127.0.0.1', 16379), server_type='redis', server_version=(7,2)).serve_forever()
