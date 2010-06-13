// OSC initialization
OscRecv recv;
// use port 6449 (or whatever)
6449 => recv.port;
// start listening (launch thread)
recv.listen();

// create osc listener thingy
recv.event( "/plinker/ssh, f" ) @=> OscEvent @ oeSSH;


// allmighty beat variables
140 => float bpm;
1::minute/bpm * 4 => dur takt;
1::minute/bpm * 2 => dur halbe;
1::minute/bpm => dur viertel;
1::minute/bpm/2 => dur achtel;
1::minute/bpm/4 => dur sechzehntel;

dur beat_variables[5];
[takt, halbe, viertel, achtel, sechzehntel] @=> beat_variables;

// sync
takt - (now % takt) => now;

// initialize clarinet
Clarinet ssh_clarinet => JCRev ssh_clarinet_rev => dac;
0.8 => ssh_clarinet_rev.gain;

0.8 => ssh_clarinet.reed;
0.4 => ssh_clarinet.noiseGain;
8.3 => ssh_clarinet.vibratoFreq;
0.2 => ssh_clarinet.vibratoGain;
0.7 => ssh_clarinet.pressure; 

// initialize pause_probability
// TODO: find a cool startup value for this.
100 => int pause_probability;

// initialize clarinet tones
int ssh_clarinet_tones[7];
[220, 264, 293, 330, 352, 396, 440] @=> ssh_clarinet_tones;


// start up the listener
spork ~listen_ssh_clarinet();

// neverending while loop.
while (true)
{
    10::second => now;
}

fun void listen_ssh_clarinet()
{
    // spork the player.
    spork ~play_ssh_clarinet();
    
    float ssh_packets;
    while (true)
    {
        oeSSH => now;
        
        // listen to osc
        while (oeSSH.nextMsg() )
        {
            // change probability of pauses during clarinet play
            // (according to packet number)
            // -> ssh_clarinet_rev
            oeSSH.getFloat() => ssh_packets;
            <<< "ssh_value:" + ssh_packets >>>;
        }
    }
    
}

fun void play_ssh_clarinet()
{
    int random_or_not;
    while (true)
    {
        // randomly, play or don't play notes.
        Std.rand2(0,100) => random_or_not;
        if (random_or_not > 25)
        {    
            // play random tones
            ssh_clarinet_tones[Std.rand2(0,6)] => ssh_clarinet.freq;
            0.6 => ssh_clarinet.noteOn;
            // travel through time, aka wait some time
            // do this also random
            beat_variables[Std.rand2(0,4)] => now;
        }
        else
        {
            // travel through time, aka wait some time
            // do this also random
            ssh_clarinet.noteOff(0.9);
            beat_variables[Std.rand2(0,4)] => now;
        }
    }
}