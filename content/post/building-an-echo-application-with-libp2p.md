---
title: "Building an echo application with libp2p"
date: 2021-01-20T8:45:30+05:30
draft: false
summary: Creating a libp2p echo application with gorpc and Kademlia DHT peer discovery 
image: images/agra4.webp
tags:
- Go
- libp2p
- gorpc
- Kademlia DHT

---

Recently I had the opportunity to work on a project that uses libp2p. It uses a Kademlia DHT for peer discovery and performs rpc call using the libp2p-gorpc library. I finally had the chance to create something using the technologies I researched and discovered for my master thesis. It was great to see discover how these libraries work and to get something up and running. There are enough good code examples of parts on github, although it was rather difficult to find a good guide or tutorial that described the details I was looking for. That's why I created a basic skeleton application with an architecture that can be extended easily.

You can find the source of the project at [github.com/ldej/echo](https://github.com/ldej/echo).

## Host

The first thing to do in a libp2p application, is creating a `Host`. The host is the center-piece of the communication with peers. 

I'm going to use the words **peer** and **node** interchangeably. When I use these, I mean a running instance of the application.

A [`Host`](https://godoc.org/github.com/libp2p/go-libp2p-core/host#Host) contains all the core functionalities you require connecting one peer to another. A `Host` contains an [`ID`](https://godoc.org/github.com/libp2p/go-libp2p-core/peer#ID) which is the identity of a peer. The `Host` also contains a [`Peerstore`](https://godoc.org/github.com/libp2p/go-libp2p-core/peerstore#Peerstore) which is like an address book. With a `Host` you can `Connect` to other peers and create [`Streams`](https://godoc.org/github.com/libp2p/go-libp2p-core/network#Stream) between them. A `Stream` represents a communication channel between two peers in a libp2p network.  

A peer's ID is derived from its public key. This means that in order to create a `Host`, a public-private key pair needs to be generated first. In the following except, I have created a function called `NewHost`, which creates a private-public key pair and a host.

{{<filename "host.go">}}
```go {hl_lines=[28,33]}
package main

import (
	"context"
	"crypto/rand"
	"fmt"
	"io"
	mrand "math/rand"

	"github.com/libp2p/go-libp2p"
	"github.com/libp2p/go-libp2p-core/crypto"
	"github.com/libp2p/go-libp2p-core/host"
	"github.com/multiformats/go-multiaddr"
)

func NewHost(ctx context.Context, seed int64, port int) (host.Host, error) {

	// If the seed is zero, use real cryptographic randomness. Otherwise, use a
	// deterministic randomness source to make generated keys stay the same
	// across multiple runs
	var r io.Reader
	if seed == 0 {
		r = rand.Reader
	} else {
		r = mrand.New(mrand.NewSource(seed))
	}

	priv, _, err := crypto.GenerateKeyPairWithReader(crypto.RSA, 2048, r)
	if err != nil {
		return nil, err
	}

	addr, _ := multiaddr.NewMultiaddr(fmt.Sprintf("/ip4/0.0.0.0/tcp/%d", port))

	return libp2p.New(ctx,
		libp2p.ListenAddrs(addr),
		libp2p.Identity(priv),
	)
}
```

When you develop an application, you might want to have a predictable identifier for your application on each run. It makes it easier to connect and to debug. This is why a different source of randomness is chosen. The [chat example of libp2p](https://github.com/libp2p/go-libp2p-examples/blob/master/chat/chat.go#L113) is doing the same thing. Golang's `crypto/rsa` library wants to prevent predictability, so they included [`randutil.MaybeReadByte(random)`](https://github.com/golang/go/blob/4b09c8ad6fb9d30b9c3417b5364809ff0006749d/src/crypto/rsa/rsa.go#L257), which means that even though you want predictability, you don't get it. [An issue](https://github.com/libp2p/go-libp2p-examples/issues/20) has been opened at the go-libp2p-examples repository, explaining that `Ed25519` can be used instead of `RSA`.

On line 33 a new address is created where the host will be listening on. When you provide `0` as the port, it will automatically find an available port for you.

## Peer discovery: DHT or mDNS?

After creating a host, how are hosts going to discover each other? There are two options available within libp2p: multicast DNS ([mDNS](https://en.wikipedia.org/wiki/Multicast_DNS)) and a Distributed Hash Table ([DHT](https://en.wikipedia.org/wiki/Distributed_hash_table)).

mDNS sends a multicast UDP message on port 5353, announcing its presence. This is for example used by Apple Bonjour or by printers. It works on local networks, but of course it doesn't work over the internet.

A DHT can be used to discover peers as well. When a peer joins a DHT, it can use the key-value store to announce it presence and to find other peers in the network. The key used for announcing its presence is called the rendezvous-point.

There are two major differences between using mDNS or a DHT for discovering peers. The first one I mentioned already, mDNS doesn't work over the internet, where a DHT does. The second difference is that a DHT requires bootstrapping nodes. Other nodes can join the network by connecting to a bootstrapping node, and then discover the rest of the network.

## Local Kademlia DHT

In the code below, a DHT is started, and a connection is made to the bootstrap peers that are provided using a parameter. At lines 18-20 an option is added to instruct the peer that, in case no bootstrap peers are provided, it should go into server mode. In server mode, it acts as a bootstrapping node, allowing other peers to join it.

For this to work, I had to enable UPnP in the configuration of my router. In case you don't want to or do not have access to that, try running the nodes in a virtual machine or in docker containers.

In case you want to join the global Kademlia DHT of libp2p, you can use the bootstrap peers in `dht.DefaultBootstrapPeers`.

{{<filename "dht.go">}}
```go {hl_lines=["18-20"]}
package main

import (
	"context"
	"log"
	"sync"

	"github.com/libp2p/go-libp2p-core/host"
	"github.com/libp2p/go-libp2p-core/peer"
	disc "github.com/libp2p/go-libp2p-discovery"
	"github.com/libp2p/go-libp2p-kad-dht"
	"github.com/multiformats/go-multiaddr"
)

func NewKDHT(ctx context.Context, host host.Host, bootstrapPeers []multiaddr.Multiaddr) (*disc.RoutingDiscovery, error) {
	var options []dht.Option

	if len(bootstrapPeers) == 0 {
		options = append(options, dht.Mode(dht.ModeServer))
	}

	kdht, err := dht.New(ctx, host, options...)
	if err != nil {
		return nil, err
	}

	if err = kdht.Bootstrap(ctx); err != nil {
		return nil, err
	}
	
	for _, peerAddr := range bootstrapPeers {
		peerinfo, _ := peer.AddrInfoFromP2pAddr(peerAddr)

		wg.Add(1)
		go func() {
			defer wg.Done()
			if err := host.Connect(ctx, *peerinfo); err != nil {
				log.Printf("Error while connecting to node %q: %-v", peerinfo, err)
			} else {
				log.Printf("Connection established with bootstrap node: %q", *peerinfo)
			}
		}()
	}
	wg.Wait()

	return disc.NewRoutingDiscovery(kdht), nil
}
```

## Discovering other peers

With the DHT set up, it's time to discover other peers. First, on line 15, the DHT gets wrapped into a `discovery.RoutingDiscovery` object. The `RoutingDiscovery` provides the `Advertise` and `FindPeers` functions. 

The `Advertise` function starts a go-routine that keeps on advertising until the context gets cancelled. It announces its presence every 3 hours. This can be shortened by providing a TTL (time to live) option as a fourth parameter.

The `FindPeers` function provides us with all the peers that have been discovered at the rendezvous-point. Since the node itself is also part of the discovered peers, it needs to be filtered out (line 33). For all the other peers, check if they are connected already, if not, then `Dial` them to create a connection.

{{<filename "discover.go">}}
```go {hl_lines=[15,33,"36-41"]}
package main

import (
	"context"
	"log"
	"time"

	"github.com/libp2p/go-libp2p-core/host"
	"github.com/libp2p/go-libp2p-core/network"
	"github.com/libp2p/go-libp2p-discovery"
	"github.com/libp2p/go-libp2p-kad-dht"
)

func Discover(ctx context.Context, h host.Host, dht *dht.IpfsDHT, rendezvous string) {
	var routingDiscovery = discovery.NewRoutingDiscovery(dht)
	discovery.Advertise(ctx, routingDiscovery, rendezvous)

	ticker := time.NewTicker(time.Second * 1)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:

			peers, err := discovery.FindPeers(ctx, routingDiscovery, rendezvous)
			if err != nil {
				log.Fatal(err)
			}

			for _, p := range peers {
				if p.ID == h.ID() {
					continue
				}
				if h.Network().Connectedness(p.ID) != network.Connected {
					_, err = h.Network().DialPeer(ctx, p.ID)
					if err != nil {
						continue
					}
				}
			}
		}
	}
}
```

## RPC

Now that peers have been discovered, it's time to set up RPC using `go-libp2p-gorpc`. Let's add a simple function that sends a message to all peers, and each peer echoes the same message back.

{{<filename "rpc_api.go">}}
```go {hl_lines=[6,7,"10-12","18-21"]}
package main

import "context"

const (
	EchoService         = "EchoRPCAPI"
	EchoServiceFuncEcho = "Echo"
)

type EchoRPCAPI struct {
	service *Service
}

type Envelope struct {
	Message string
}

func (e *EchoRPCAPI) Echo(ctx context.Context, in Envelope, out *Envelope) error {
	*out = r.service.ReceiveEcho(in)
	return nil
}
```

An rpc service consists of a struct (lines 10-12) with a methods defined on it. In this case there is one rpc method called `Echo` defined on lines 18-21. An rpc method needs to have a specific signature:
- the receiver needs to be a pointer (`e *EchoRPCAPI`)
- the first parameter needs to be a `context.Context`
- the second parameter, the incoming data, needs to be a concrete type
- the third parameter, the outgoing data, needs to be a pointer
- the return type has to be `error`

In the example implementation an `Envelope` struct is defined which is used for both the incoming and the outgoing data. In case no incoming data is required an empty struct can be defined as a parameter: `in struct{}`. In case no outgoing data is required a pointer to an empty struct can be used as a parameter: `out *struct{}`.

To separate the rpc logic from the "business logic" the `EchoRPCAPI` has a `service` which is used in the `Echo` method.

On line 6 and 7 two strings are defined which will be used in the code below. The first one represents the exact name of the struct for the `EchoRPCAPI`, the second represents the name of the `Echo` method that will be called.

## Service

With the echo rpc set up, let's take a look at the service that calls it.

First, let's take a look at the `SetupRPC` method. It creates `rpc.Server`, this server is used to receive calls from other peers. Then it creates an instance of `EchoRPCAPI` and registers it with the server. Finally, it creates an `rpc.Client` and passes the `rpc.Server` as an argument. The `rpc.Client` can perform call on its own server as if it's just another peer.

{{<filename "service.go">}}
```go {hl_lines=["29-39","57-77"]}
package main

import (
	"context"
	"fmt"
	"time"

	"github.com/libp2p/go-libp2p-core/host"
	"github.com/libp2p/go-libp2p-core/protocol"
	"github.com/libp2p/go-libp2p-gorpc"
)

type Service struct {
	rpcServer *rpc.Server
	rpcClient *rpc.Client
	host      host.Host
	protocol  protocol.ID
	counter   int
}

func NewService(host host.Host, protocol protocol.ID) *Service {
	return &Service{
		host:     host,
		protocol: protocol,
	}
}

func (s *Service) SetupRPC() error {
	s.rpcServer = rpc.NewServer(s.host, s.protocol)

	echoRPCAPI := EchoRPCAPI{service: s}
	err := s.rpcServer.Register(&echoRPCAPI)
	if err != nil {
		return err
	}

	s.rpcClient = rpc.NewClientWithServer(s.host, s.protocol, s.rpcServer)
	return nil
}

func (s *Service) StartMessaging(ctx context.Context) {
	ticker := time.NewTicker(time.Second * 1)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			s.counter++
			s.Echo(fmt.Sprintf("Message (%d): Hello from %s", s.counter, s.host.ID().Pretty()))
		}
	}
}

func (s *Service) Echo(message string) {
	peers := s.host.Peerstore().Peers()
	var replies = make([]*Envelope, len(peers))

	errs := s.rpcClient.MultiCall(
		Ctxts(len(peers)),
		peers,
		EchoService,
		EchoServiceFuncEcho,
		Envelope{Message: message},
		CopyEnvelopesToIfaces(replies),
	)

	for i, err := range errs {
		if err != nil {
			fmt.Printf("Peer %s returned error: %-v\n", peers[i].Pretty(), err)
		} else {
			fmt.Printf("Peer %s echoed: %s\n", peers[i].Pretty(), replies[i].Message)
		}
	}
}

func (s *Service) ReceiveEcho(envelope Envelope) Envelope {
	return Envelope{Message: fmt.Sprintf("Peer %s echoing: %s", s.host.ID(), envelope.Message)}
}

func Ctxts(n int) []context.Context {
	ctxs := make([]context.Context, n)
	for i := 0; i < n; i++ {
		ctxs[i] = context.Background()
	}
	return ctxs
}

func CopyEnvelopesToIfaces(in []*Envelope) []interface{} {
	ifaces := make([]interface{}, len(in))
	for i := range in {
		in[i] = &Envelope{}
		ifaces[i] = in[i]
	}
	return ifaces
}
```

And then this is what we've been building up to: performing a remote procedure call. On lines 57 to 77 a remote procedure call is done. The call is addressed to all peers in the `PeerStore`, which includes the peer itself. In this case a `MultiCall` is performed. 

The `MultiCall` method has a signature that took me some time to get used to. The **first** argument is a slice of contexts, one for each peer. The context is the first parameter of the `Echo` method that has been defined on the the `EchoRPCAPI`. The **second** argument is the list of peers that the call should be performed on. The **third** parameter is the name of the service that should be called, in this case it is the `EchoRPCAPI` which has already been defined in the `EchoService` constant in `rpc_api.go`. The **fourth** argument is the method that should be called, in this case the `Echo` method as defined in the constant `EchoServiceFuncEcho`. The **fifth** parameter is the `in` parameter of the `Echo` method. This is not a slice, so this means that every peer will receive exactly the same value. If you want different values for different peers, you need to use `rpc.Server.Call` instead of `MultiCall` and perform a call to each peer individually. The **sixth** and final parameter is for the replies. The parameter only accepts a slice of interfaces which consist of pointers to the actual objects that in the end will contain the replies. The `Ctxts` and `CopyEnvelopesToIfaces` are there to help create the right data structures for those parameters. This is a strategy that I found in the [ipfs-cluster](https://github.com/ipfs/ipfs-cluster/blob/master/rpcutil/rpcutil.go) project. It also includes a `RPCDiscardReplies` function which is useful for doing a `MultiCall` to an rpc method that has to response type.

The `MultiCall` method returns a slice which has the exact length of the number of peers that the call has been done to. This allows for iteration over the slice of errors to check if any of them returned an error. There is a variety of errors that can be returned. For example when a peer is unreachable, it will return a `dial backoff` error. When the `Echo` function returns an error (instead of the `nil` that is returned now), it will be an error in this slice.

## Tying it all together

With all the parts set up, it's time to assemble the parts in `main.go`. Command line flags are used to parameterize the application. Then a host is created, the DHT is started, the service with rpc is set up and finally discovering of peers and sending of messages are started.

{{<filename "main.go">}}
```go
package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"strings"
	"syscall"

	"github.com/libp2p/go-libp2p-core/host"
	"github.com/libp2p/go-libp2p-core/protocol"
	"github.com/multiformats/go-multiaddr"
)

func main() {
	config := Config{}

	flag.StringVar(&config.Rendezvous, "rendezvous", "ldej/echo", "")
	flag.Int64Var(&config.Seed, "seed", 0, "Seed value for generating a PeerID, 0 is random")
	flag.Var(&config.DiscoveryPeers, "peer", "Peer multiaddress for peer discovery")
	flag.StringVar(&config.ProtocolID, "protocolid", "/p2p/rpc/ldej", "")
	flag.IntVar(&config.Port, "port", 0, "")
	flag.Parse()

	ctx, cancel := context.WithCancel(context.Background())

	h, err := NewHost(ctx, config.Seed, config.Port)
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("Host ID: %s", h.ID().Pretty())
	log.Printf("Connect to me on:")
	for _, addr := range h.Addrs() {
		log.Printf("  %s/p2p/%s", addr, h.ID().Pretty())
	}

	dht, err := NewDHT(ctx, h, config.DiscoveryPeers)
	if err != nil {
		log.Fatal(err)
	}
	
	service := NewService(h, protocol.ID(config.ProtocolID))
	err = service.SetupRPC()
	if err != nil {
		log.Fatal(err)
	}

	go Discover(ctx, h, dht, config.Rendezvous)
	go service.StartMessaging(ctx)

	run(h, cancel)
}

func run(h host.Host, cancel func()) {
	c := make(chan os.Signal, 1)

	signal.Notify(c, os.Interrupt, syscall.SIGHUP, syscall.SIGINT, syscall.SIGTERM)
	<-c

	fmt.Printf("\rExiting...\n")

	cancel()

	if err := h.Close(); err != nil {
		panic(err)
	}
	os.Exit(0)
}

type Config struct {
	Port           int
	ProtocolID     string
	Rendezvous     string
	Seed           int64
	DiscoveryPeers addrList
}

type addrList []multiaddr.Multiaddr

func (al *addrList) String() string {
	strs := make([]string, len(*al))
	for i, addr := range *al {
		strs[i] = addr.String()
	}
	return strings.Join(strs, ",")
}

func (al *addrList) Set(value string) error {
	addr, err := multiaddr.NewMultiaddr(value)
	if err != nil {
		return err
	}
	*al = append(*al, addr)
	return nil
}

```

## Running the application

```shell
$ git clone git@github.com:ldej/echo.git
$ go run .
2021/01/20 12:56:42 Host ID: QmNpf6rQUFFTR9syqLASvzTsfDdBaUYvu3QkgVMXodyJUz
2021/01/20 12:56:42 Connect to me on:
2021/01/20 12:56:42   /ip4/192.168.1.8/tcp/45363/p2p/QmNpf6rQUFFTR9syqLASvzTsfDdBaUYvu3QkgVMXodyJUz
2021/01/20 12:56:42   /ip4/127.0.0.1/tcp/45363/p2p/QmNpf6rQUFFTR9syqLASvzTsfDdBaUYvu3QkgVMXodyJUz

$ # open a second terminal
$ go run . -peer /ip4/192.168.1.8/tcp/45363/p2p/QmNpf6rQUFFTR9syqLASvzTsfDdBaUYvu3QkgVMXodyJUz
2021/01/20 12:57:45 Host ID: QmSP59U51bSsERKobDE4CyrChJ4uSWv6RV1kiAs51DLLRF
2021/01/20 12:57:45 Connect to me on:
2021/01/20 12:57:45   /ip4/192.168.1.8/tcp/39957/p2p/QmSP59U51bSsERKobDE4CyrChJ4uSWv6RV1kiAs51DLLRF
2021/01/20 12:57:45   /ip4/127.0.0.1/tcp/39957/p2p/QmSP59U51bSsERKobDE4CyrChJ4uSWv6RV1kiAs51DLLRF
2021/01/20 12:57:45 Connection established with bootstrap node: "{QmNpf6rQUFFTR9syqLASvzTsfDdBaUYvu3QkgVMXodyJUz: [/ip4/192.168.1.8/tcp/45363]}"

$ # open a third terminal
$ go run . -peer /ip4/192.168.1.8/tcp/45363/p2p/QmNpf6rQUFFTR9syqLASvzTsfDdBaUYvu3QkgVMXodyJUz
2021/01/20 12:59:06 Host ID: QmPLsZDrgPLFie9PkvrdBbiMa8C5W9eKjZ429kimkP2SB8
2021/01/20 12:59:06 Connect to me on:
2021/01/20 12:59:06   /ip4/192.168.1.8/tcp/42967/p2p/QmPLsZDrgPLFie9PkvrdBbiMa8C5W9eKjZ429kimkP2SB8
2021/01/20 12:59:06   /ip4/127.0.0.1/tcp/42967/p2p/QmPLsZDrgPLFie9PkvrdBbiMa8C5W9eKjZ429kimkP2SB8
2021/01/20 12:57:45 Connection established with bootstrap node: "{QmNpf6rQUFFTR9syqLASvzTsfDdBaUYvu3QkgVMXodyJUz: [/ip4/192.168.1.8/tcp/45363]}"
```

## Managing peers

In a peer-to-peer system, you never know when peers leave or when they become unavailable. The `PeerStore` remembers peers until their [TTL (Time To Live)](https://godoc.org/github.com/libp2p/go-libp2p-core/peerstore#pkg-variables) has expired. In the `DHT` a peer announces its presence every 3 hours. In this example application the leaving of peers is not managed at all. Depending on the requirements of your application this might be important, or not. 

## Conclusion

And there you have it, a basic libp2p application that uses Kademlia DHT for peer discovery and that can perform calls using rpc. In the end it was a lot of fun to figure it all out and build it, I am happy with the result and I'm going to use this as a basis for creating more decentralized applications.

In a future post I'm going to take a look at implementing [logical clocks](https://www.cs.uic.edu/~ajayk/Chapter3.pdf) and I might take a look at consensus algorithms.