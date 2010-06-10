OscRecv recv;
// use port 6449 (or whatever)
6449 => recv.port;
// start listening (launch thread)
recv.listen();

140 => float bpm;
1::minute/bpm * 4 => dur takt;
1::minute/bpm * 2 => dur halbe;
1::minute/bpm => dur viertel;
1::minute/bpm/2 => dur achtel;
1::minute/bpm/4 => dur sechzehntel;

viertel => dur web_duration;



// create an address in the receiver, store in new variable
recv.event( "/plinker/out/port/80, f" ) @=> OscEvent @ oeOutWeb;
recv.event( "/plinker/in/port/80, f" ) @=> OscEvent @ oeInWeb;

Rhodey voc=> JCRev r => Echo a => Echo b => Echo c => dac;
    
spork ~ web_listener();    

while(true){
    10::second => now;
}

fun void web_listener(){
   spork ~ web_player();
   
   while(true){
        oeOutWeb => now;
        oeInWeb => now;
        
        while( oeOutWeb.nextMsg() )
        { 
            <<< "FOO" >>>;
            oeOutWeb.getFloat() => float outFactor;
            <<< "Float: " + outFactor>>>;
            
        }
 
        while( oeInWeb.nextMsg() )
        { 
            <<< "BAR" >>>;
            <<< "Float: " + oeInWeb.getFloat()>>>;
        }
        
    }
}

fun void web_player(){

    [ 0, 4, 2, 7, 9, 11, 9, 7 ] @=> int scale[];

    220.0 => voc.freq;
    0.8 => voc.gain;
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
            web_duration => now;
        }
        
    }
}