/*
	 tcpfilter

	 Daniel D. Lee, 10/99
	 <ddlee@physics.lucent.com>
	 */

#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/signal.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

#define BUF_LENGTH 8192
#define MAX(A,B) ((A)>(B) ? (A) : (B))

int main(int argc, char **argv)
{
	int sock_fd, port;
	char buf[BUF_LENGTH];
	int i, buflen;
	struct sockaddr_in serv_addr;
	struct hostent *hostptr;
	fd_set readfs;
	int maxfd, loop;

	if (argc < 3) {
		fprintf(stderr,"Usage: tcpfilter host port\n");
		exit(1);
	}
	if ((hostptr = gethostbyname(argv[1])) == NULL) {
		perror("Could not get hostname.");
		exit(1);
	}
	port = atoi(argv[2]);

	bzero((char *) &serv_addr, sizeof(serv_addr));
	serv_addr.sin_family = AF_INET;
	bcopy(hostptr->h_addr, (char *) &serv_addr.sin_addr, hostptr->h_length);
	serv_addr.sin_port = htons(port);

	/* Open TCP socket */
	if ((sock_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
		perror("Could not open socket");
		exit(1);
	}
	if (connect(sock_fd, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0)
		perror("Could not connect to server");

	maxfd = sock_fd+1;
	loop = 1;
	while (loop) {
		FD_SET(0, &readfs);
		FD_SET(sock_fd, &readfs);
		select(maxfd, &readfs, NULL, NULL, NULL);

		if (FD_ISSET(0, &readfs)) {
			buflen = read(0, buf, BUF_LENGTH);
			if (buflen == 0)
				loop = 0;
			else
				write(sock_fd,buf,buflen);
		}

		if (FD_ISSET(sock_fd, &readfs)) {
			buflen = read(sock_fd, buf, BUF_LENGTH);
			if (buflen == 0)
				loop = 0;
			else
				write(1,buf,buflen);
		}
	}

	close(sock_fd);
}
