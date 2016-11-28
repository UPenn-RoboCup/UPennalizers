clear all;
recv_fd = udp_recv('new', 54321);
udp_recv('getQueueSize', recv_fd);
s_udp = zmq( 'fd', recv_fd );

while 1
    [data,idx] = zmq('poll',1000);
    if numel(idx)~=0
        udp_data = udp_recv('receive', recv_fd);
        if numel(udp_data)>0
            fprintf('data amount: %d bytes.\n', numel(udp_data) )
        end
    else
        disp('no data');
    end
end
