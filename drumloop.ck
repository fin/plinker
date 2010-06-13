140 => float bpm;
1::minute/bpm * 4 => dur takt;
1::minute/bpm * 2 => dur halbe;
1::minute/bpm => dur viertel;
1::minute/bpm/2 => dur achtel;
1::minute/bpm/4 => dur sechzehntel;

OscRecv recv;
// use port 6449 (or whatever)
6449 => recv.port;
// start listening (launch thread)
recv.listen();

//rec.event( "/plinker/out/port/80, f" ) @=> OscEvent @ oeOutWeb;
//recv.event( "/plinker/in/port/80, f" ) @=> OscEvent @ oeInWeb;

5 => int glob_msg;

SndBuf drums[6];
string filename[6];

"Alesis_HR16A_03.wav" => filename[0];
"Alesis_HR16A_47.wav" => filename[1];
"Alesis_HR16A_16.wav" => filename[2];
"Alesis_HR16A_28.wav" => filename[3];
"Alesis_HR16A_17.wav" => filename[4];
"Alesis_HR16A_10.wav" => filename[5];

[1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0]  @=> int bd_row[];
[0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,1]  @=> int sd_row[];
[0,1,1,0,0,1,1,0,0,1,1,1,0,1,1,0]  @=> int ch_row[];
[0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1]  @=> int oh_row[];
[0,0,0,0,1,0,0,0,0,0,0,0,1,0,1,0]  @=> int cp_row[];
[0,1,1,1,0,1,1,0,0,1,1,1,0,1,1,0]  @=> int cb_row[];

<<<"Loading drums...">>>;
// load the filename[] to drums[]
for (0 => int k; k<6; k++)
{
    filename[k] => drums[k].read;
}
<<<"...done">>>;

<<<"Connecting drums to dac...">>>;
//connect drums[] to dac and set gain
for (0 => int j; j<6; j++)
{
    0.3 => drums[j].gain;
    drums[j] => dac;
}
<<<"...done">>>;


fun void play_drums()
{
    takt - (now % takt) => now; //synch am taktbeginn
    //0 => int drum_index;
    0 => int curr_pos;
    <<<"Play the drums">>>;
    while(true)
    {
        //update_drum_row();
        //<<<"drum_index: ", drum_index>>>;
        //drums[drum_index].play;
    
        if (bd_row[curr_pos])
        {
            0 => drums[0].pos; 
            <<<"BD">>>;
        }
        if (glob_msg > 0)
        {
            if (sd_row[curr_pos])
            {
                0 => drums[1].pos; 
                <<<"SD">>>;
            }
            if (glob_msg > 1)
            {
                if (ch_row[curr_pos])
                {
                    0 => drums[2].pos; 
                    <<<"CH">>>;
                }
                if (glob_msg > 2)
                {
                    if (oh_row[curr_pos])
                    {
                        0 => drums[3].pos; 
                        <<<"OH">>>;
                    }
                    if (glob_msg > 3)
                    {
                        if (cp_row[curr_pos])
                        {
                            0 => drums[4].pos; 
                            <<<"CP">>>;
                        }
                        if (glob_msg > 4)
                        {
                            if (cb_row[curr_pos])
                            {
                                0 => drums[5].pos; 
                                <<<"CB">>>;
                            }
                        }
                    }
                }
            }
        }
        (curr_pos +1)%16 => curr_pos;
        <<<curr_pos>>>;
        1::sechzehntel => now;
    }
}

spork ~ play_drums();

while (true)
{
  1::second => now;
}
