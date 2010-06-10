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


// initialize clarinet tones
int ssh_clarinet_tones[5];
[220, 293, 330, 352, 440] @=> ssh_clarinet_tones;


spork ~play_ssh_clarinet();

// neverending while loop.
while (true)
{
    10::second => now;
}

fun void listen_ssh_clarinet()
{
    while (true)
    {
        // listen to osc
        // change volume of clarinet ( according to
        // packet number)
        // -> ssh_clarinet_rev
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
            ssh_clarinet_tones[Std.rand2(0,4)] => ssh_clarinet.freq;
            0.6 => ssh_clarinet.noteOn;
            // travel through time, aka wait some time
            // do this also random
            beat_variables[Std.rand2(0,4)] => now;
        }
        else
        {
            <<< "PAUSE" >>>;
            // travel through time, aka wait some time
            // do this also random
            ssh_clarinet.noteOff(0.9);
            beat_variables[Std.rand2(0,4)] => now;
        }
    }
}