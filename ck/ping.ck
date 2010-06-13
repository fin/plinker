// (launch with s.ck)

// the patch
Flute f => JCRev r => dac;
.5 => f.gain;
.1 => r.mix;

// create our OSC receiver
OscRecv recv;
// use port 6449 (or whatever)
6449 => recv.port;
// start listening (launch thread)
recv.listen();

// create an address in the receiver, store in new variable
recv.event( "/plinker/ping,i" ) @=> OscEvent @ oe;

while( true )
{
    oe => now;
    <<< "ping" >>>;

    while( oe.nextMsg() )
    { 
        <<< "ping" >>>;
        1 => f.noteOn;
        0.1::second => now;
        1 => f.noteOff;
    }
}
