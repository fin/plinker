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
recv.event( "/plinker/inout,f" ) @=> OscEvent @ oeDrumFilter;
recv.event( "/plinker/count,f" ) @=> OscEvent @ oeDrumLayers;

0 => int glob_msg;
4 => int drumfilter; //Startindex für drumfilter
1 => float last_count;
1 => float curr_count;

[50, 100, 500, 1000, 2000, 3000, 4000, 5000, 6000] @=> int drumfilter_cutoff[];
7 => int MAX_LAYERS;
8 => int MAX_CUTOFF;

SndBuf drums[MAX_LAYERS];
string filename[MAX_LAYERS];

"_sample_BD.wav" => filename[0]; //BD
"_sample_SD.wav" => filename[1]; //SD
"_sample_CH.wav" => filename[2]; //CH
"_sample_OH.wav" => filename[3]; //OH
"_sample_CP.wav" => filename[4]; //CP
"_sample_CB1.wav" => filename[5]; //CB
"_sample_CB2.wav" => filename[6]; //CB2

[1,0,0,0,1,0,0,1,1,0,0,0,1,0,0,0]  @=> int bd_row[];
[0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,1]  @=> int cp_row[];
[0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,1]  @=> int sd_row[];
[0,1,1,0,0,1,1,0,0,1,1,1,0,1,1,0]  @=> int ch_row[];
[0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1]  @=> int oh_row[];
[0,1,1,1,0,1,1,0,0,1,1,1,0,1,1,0]  @=> int cb_row[];
[1,1,0,0,1,1,0,0,1,1,0,0,1,1,1,1]  @=> int cb2_row[];

<<<"Loading drums...">>>;
// load the filename[] to drums[]
for (0 => int k; k<MAX_LAYERS; k++)
{
    filename[k] => drums[k].read;
}
<<<"...done">>>;

<<<"Connecting drums to dac...">>>;
//connect drums[] to dac and set gain

LPF filter[MAX_LAYERS];

for (0 => int j; j<MAX_LAYERS; j++)
{
    0.3 => drums[j].gain;
    //0.01 => filter[j].Q;
    drumfilter_cutoff[drumfilter] => filter[j].freq;
    drums[j] => filter[j] => dac;
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
            //<<<"BD">>>;
        }
        if (glob_msg > 0)
        {
            if (cp_row[curr_pos])
            {
                0 => drums[4].pos; 
                //<<<"CP">>>;
            }
            if (glob_msg > 1)
            {
                if (sd_row[curr_pos])
                {
                    0 => drums[1].pos; 
                    //<<<"SD">>>;
                }
                if (glob_msg > 2)
                {
                    if (oh_row[curr_pos])
                    {
                        0 => drums[3].pos; 
                        //<<<"OH">>>;
                    }
                    if (glob_msg > 3)
                    {
                        if (ch_row[curr_pos])
                        {
                            0 => drums[2].pos; 
                            //<<<"CH">>>;
                        }
                        if (glob_msg > 4)
                        {
                            if (cb_row[curr_pos])
                            {
                                0 => drums[5].pos; 
                                //<<<"CB">>>;
                            }
                            if (glob_msg > 5)
                            {
                                if (cb2_row[curr_pos])
                                {
                                    0 => drums[6].pos; 
                                    //<<<"CB2">>>;
                                }
                            }
                        }
                    }
                }
            }
        }
        (curr_pos +1)%16 => curr_pos;
        //<<<curr_pos>>>;
        1::sechzehntel => now;
    }
}

fun void count_listener()
{
   while(true)
   {
       <<< "trying recv count" >>>;
        oeDrumLayers => now;
        <<< "recv count" >>>;
        while( oeDrumLayers.nextMsg() )
        { 
            1 => float factor;
            //<<< "FOO" >>>;
            oeDrumLayers.getFloat() => float osc_count;
            //<<< "Float osc_count: " + osc_count >>>;
            curr_count => last_count;
            osc_count => curr_count;
            if (last_count != 0)
            {
                curr_count / last_count => factor;
            }
            else 
            {
                curr_count => factor;
            }
            //<<< "Float factor: " + factor >>>;
            if (factor > 1 && glob_msg < MAX_LAYERS)
            {
                glob_msg++;
            } 
            else if (factor < 0.5 && glob_msg > 0)
            {
                glob_msg--;
            }
        }
    }
}

fun void inout_listener()
{
   
   while(true)
   {
       <<< "trying recv inout" >>>;
        oeDrumFilter => now;
        <<< "recv inout" >>>;
        while( oeDrumFilter.nextMsg() )
        { 
            //<<< "FOO" >>>;
            oeDrumFilter.getFloat() => float factor;
            <<< "Float: " + factor >>>;
            if (factor > 2 && drumfilter < MAX_CUTOFF)
            {
                drumfilter++;
            } 
            else if (factor < 0.5 && drumfilter > 0)
            {
                drumfilter--;
            }
            for (0 => int l; l<MAX_LAYERS; l++)
            {
                drumfilter_cutoff[drumfilter] => filter[l].freq;
            }
        }
    }
}

spork ~ play_drums();
spork ~ inout_listener();
spork ~ count_listener();

while (true)
{
  1::second => now;
}
 