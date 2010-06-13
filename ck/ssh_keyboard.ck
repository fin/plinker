// OSC initialization
OscRecv recv;
// use port 6449 (or whatever)
9999 => recv.port;
// start listening (launch thread)
recv.listen();

// create osc listener thingy
recv.event( "/plinker/ssh, f" ) @=> OscEvent @ oeSSH;

0.9 => float max_gain;
0.1 => float min_gain;
0.1 => float ssh_gain;

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

// start up the listener
spork ~listen_ssh_keyboard();

// neverending while loop.
while (true)
{
    10::second => now;
}

fun void listen_ssh_keyboard()
{
    // spork the player.
    //spork ~play_ssh_clarinet();
    
    float ssh_packets;
    float gain;
  
    while (true)
    {
        oeSSH => now;
        
        // listen to osc
        while (oeSSH.nextMsg() )
        {
            oeSSH.getFloat() => ssh_packets;
            if (ssh_packets > 1.0)
                0.5 + ( 0.1 * ssh_packets $ int) => gain;
            else
                0.3 => gain;
            
            if (gain > 0.8)
                0.8 => gain;
            
            spork ~play_ssh_keyboard(gain);
            
            <<< "ssh_value:" + ssh_packets >>>;
            <<< "gain:" + gain >>>;
            
        }
    }
    
}

fun void play_ssh_keyboard(float gainor)
{
    SndBuf keyboard_buffer;
    // keyboard buffer
    "keyboard2.wav" => keyboard_buffer.read;
    gainor => keyboard_buffer.gain;
    0 => keyboard_buffer.loop;
    keyboard_buffer => dac;

    5::second => now;
}