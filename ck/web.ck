OscRecv recv;
// use port 6449 (or whatever)
9999 => recv.port;
// start listening (launch thread)
recv.listen();

140 => float bpm;
1::minute/bpm => dur viertel;
viertel => dur web_duration;

1.0 => float maxfactor;

// create an address in the receiver, store in new variable
recv.event( "/plinker/web,f" ) @=> OscEvent @ oeWeb;

Rhodey voc=> JCRev r => Echo a => Echo b => Echo c => dac;
    
spork ~ web_listener();    

while(true){
    10::second => now;
}

fun void web_listener(){
   0.0 => float vocgain;
   
   spork ~ web_player();
   
   while(true){
        oeWeb => now;
        while( oeWeb.nextMsg() )
        { 
            oeWeb.getFloat() => float factor;
            
            //if(factor > maxfactor){
            //   factor => maxfactor;
            //    <<<maxfactor>>>;
            //    }
            
            if(factor == 1.000){
                vocgain * 0.6 => vocgain;
                140 => bpm;
                }
            else{
                0.2 * factor => vocgain;
                140 + 10 * factor => bpm;
            }
            
            if(vocgain > 2){
                2.0 => vocgain;
                            }
            if(bpm > 280){
                280 => bpm;
                }                
            <<< "Factor: " + factor + "   ; New Gain: " + vocgain + "   BPM: " + bpm >>>;
            
            vocgain => voc.gain;
            
            
            
        }
        
    }
}

fun void web_player(){

    [ 0, 4, 2, 7, 9, 11, 9, 7 ] @=> int scale[];

    220.0 => voc.freq;
    0.0 => voc.gain;
    .8 => r.gain;
    .2 => r.mix;
    0::ms => a.max => b.max => c.max;
    750::ms => a.delay => b.delay => c.delay;
    .50 => a.mix => b.mix => c.mix;

    while(true){
        for(0 => int i; i < scale.cap(); i++){
            scale[i] => int freq;
            Std.mtof( ( 33 + freq ) ) => voc.freq;
            0.8 => voc.noteOn;
            
            1::minute/bpm => now;
        }
        
    }
}