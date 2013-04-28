                                                                     
                                                                     
                                                                     
                                             
#!/usr/bin/perl

package QC_Trend;

#######################################################################
# Trend Check 
#
# This test will look for signs of instrument drift over a period
# of 30,60,and 90 days
#
# The goal of this test is to determine if an instrument needs to be
# replaced before values that do pass, but should fail, get recorded.
#
# Author: Sean Heuser
# Date: 6/28/2011
#######################################################################

use strict;
use Buddy_util;
use Utilities;
use Flag;
use Statistics::R;

my $database_name = "cronos";
my $user = "webread";
my $password = "lighthouse8";
my $machine = "capefear.meas.ncsu.edu";

my $db = Mysql->Connect($machine,$database_name,$user,$password) or die "\nCould not connect to database '".$database_name."' as user '".$user."' at line ".__LINE__." in 'QC_Range.pm'\n\n";

#############################################################################################################################
# Pressure Minute QC.[ARIMA modeling Procedure.]
#
#
#
#
#Author: Colin Craig
#
#############################################################################################################################
sub pressure_trend($$$){
	my %data=%{$_[0]};
	my @start_dates = @{$_[1]};
	my @end_dates = @{$_[2]};
	my @Actual;
	my @Predicted;
	my @Upper_Bounds;
	my @Lower_Bounds;
	my @pres_obs;
	my @dates;

	foreach my$top (keys %data){
		@pres_obs= @{$data{$top}{'Data'}};
		@dates=@{$data{$top}{'Dates'}};
		my $station=$top;
		my $index=0;
		my $mins=Utilities::Time_Diff_int_min($start_dates[0],$end_dates[0]);
		#Ammount of past data.
		my $index_size=$#dates-$mins;
		print "$station has $#pres_obs observations for specified time frame.\n"; 


			while($index_size<$#dates){
				my $R = Statistics::R->new();
				my @new_obs_arr=();
				my @new_dates_arr=();
				print $index_size."\n";

				#Create an array of only past obs, and current hour being checked...
				for(my$q=0;$q<=$index_size;$q++){$new_obs_arr[$q]=$pres_obs[$q];
								$new_dates_arr[$q]=$dates[$q];}

				print "$new_dates_arr[$index_size].........$new_obs_arr[$index_size]\n";


				
				#################################
				#Grab the actual value...This would be removed for operational runs.
				my $Act=pop(@new_obs_arr);
				if($Act!='n' && $Act>900){
					push(@Actual,$Act);}
				else{$index_size++;$R->stopR();next;}
				#################################
				$R->send(q'x<-scan(text="'.qq'@new_obs_arr'.q'")');
				#ARIMA Tests.
				$R->send(q'test_110=arima(x,order=c(1,1,0))');
				#$R->send(q'test_111=arima(x,order=c(1,1,1))');
				print "Im here\n";
				#$R->send(q'test_112=arima(x,order=c(1,1,2))');
				print "Doing a lot of stuff. Chill out. We can do this. \n";
				#$R->send(q'test_113=arima(x,order=c(1,1,3))');
				print "kthxbai\n";
				$R->send(q'test_010=arima(x,order=c(0,1,0))');
				print "omg\n";
				$R->send(q'test_011=arima(x,order=c(0,1,1))');
				#$R->send(q'test_012=arima(x,order=c(0,1,2))');
				#$R->send(q'test_013=arima(x,order=c(0,1,3))');
	
				#Perform various ARIMA models
				#ARIMA(p,d,q) 
				#p=Autoregressive Term. 
				#d=Differencing Term/Trend Term. (makes data stationary by assessing effect of previous terms)
				#q=Moving Average Terms. (Judges effect of previous shocks on current)

				####'test_111','test_112','test_113','test_012','test_013'
				my %residuals=('test_110','test_010','test_011');

				#Grab mean residuals for each test.
				#Load Residuals into hash.

				$R->send(q'rsid_110=mean(residuals(test_110),na.rm=TRUE)');
				my $rsid_110=$R->get('rsid_110');
				$residuals{'test_110'}=abs($rsid_110);
				#$R->send(q'rsid_111=mean(residuals(test_111),na.rm=TRUE)');
				#my $rsid_111=$R->get('rsid_111');
				#$residuals{'test_111'}=abs($rsid_111);
				#$R->send(q'rsid_112=mean(residuals(test_112),na.rm=TRUE)');
				#my $rsid_112=$R->get('rsid_112');
				#$residuals{'test_112'}=abs($rsid_112);
				#$R->send(q'rsid_113=mean(residuals(test_113),na.rm=TRUE)');
				#my $rsid_113=$R->get('rsid_113');
				#$residuals{'test_113'}=abs($rsid_113);
				$R->send(q'rsid_010=mean(residuals(test_010),na.rm=TRUE,include.mean=FALSE)');
				my $rsid_010=$R->get('rsid_010');
				$residuals{'test_010'}=abs($rsid_010);
				$R->send(q'rsid_011=mean(residuals(test_011),na.rm=TRUE)');
				my $rsid_011=$R->get('rsid_011');
				$residuals{'test_011'}=abs($rsid_011);
				#$R->send(q'rsid_012=mean(residuals(test_012),na.rm=TRUE)');
				#my $rsid_012=$R->get('rsid_012');
				#$residuals{'test_012'}=abs($rsid_012);
				#$R->send(q'rsid_013=mean(residuals(test_013),na.rm=TRUE)');
				#my $rsid_013=$R->get('rsid_013');
				#$residuals{'test_013'}=abs($rsid_013);

				#Hash Sort to find lowest error.
				my @sorted=(sort {$residuals{$b} <=> $residuals{$a}} keys %residuals);
				my $res=pop(@sorted);
	
	
				$R->send(q'ACF=acf(diff(x),50,na.action=na.pass)');
				$R->send(q'pred=predict('.qq'$res'.q',n.ahead=1)');
				$R->send(q'pred$pred');
				$R->send(q'high=pred$pred+2*pred$se');
				$R->send(q'low=pred$pred-2*pred$se');


	
				use Data::Dumper;
				my @high=@{$R->get('high')};
				my @low=@{$R->get('low')};
				my @pred=@{$R->get('pred')};
				#my @ACF=$R->get('ACF$acf');
				my @ACF;

				# loop through array to print the hash pairs ordered
				foreach (keys %residuals){
					print "$_ => $residuals{$_}\n";}

				for(my$i=1;$i<51;$i++){
					if($i!=1){
						my $this=$R->get(q'ACF$acf['.qq'$i'.q']');
						#print $this;
						push(@ACF,$this);}} 
				print "Best Model: ".$res."    Err: ".$residuals{$res}."\n";
				print "HI: ".$high[12]."       LO: ".$low[12]."        Predicted: ".$pred[13]."\n";
				print "Actual: ".$Act."\n";
				push(@Predicted,$pred[13]);
				push(@Upper_Bounds,$high[12]);
				push(@Lower_Bounds,$low[12]);


				$index_size++;
				$R->stopR();  }
			#Plot for each station.

			#print "PREDICTED: \n".Dumper(@Predicted);
			#print "ACTUAL: \n".Dumper(@Actual);
			#my $R = Statistics::R->new() ;
			#my $file=$station."_plot3.pdf";
			#$R->send(q'pdf("'.qq'$file'.'",onefile=TRUE)');
			#$R->send(q'Actual<-scan(text="'.qq'@Actual'.q'")');
			#$R->send(q'Predicted<-scan(text="'.qq'@Predicted'.q'")');
			#$R->send(q'Upper<-scan(text="'.qq'@Upper_Bounds'.q'")');
			#$R->send(q'Lower<-scan(text="'.qq'@Lower_Bounds'.q'")');
			#$R->send(q'ACF=acf(diff(x),50,na.action=na.pass)');
			#$R->send(q'plot(Actual,main="'.qq'$station'.'",type="l",xlab="time",ylab="Pressure(mb)",col="red",ylim=c(1003,1007))');
			#$R->send(q'lines(Predicted,col="blue")');
			#$R->send(q'lines(Upper,col="black")');
			#$R->send(q'lines(Lower,col="black")');
			#$R->send(q'legend("bottomleft",legend=c("Observed","Predicted"),col=c("red","blue"),lwd=c(1,1))');
			#$R->send(q'dev.off()');
			#$R->send(q'wd=getwd()');
			#my $wd=$R->get(q'wd');
			#print "\nPDF stored in $wd\n";
			#$R->stopR();
			
			}

	#Compare Actual with Predicted, and High/low ranges. Check ACF. 



}

########################################################################################################################
# Pressure/Trend QC. [Generalized Linear Modeling] 
# Scores:
# Significantly negative slopes (100pts)
# 30-Day = 10pts
# 60-Day = 20pts
# 120-Day= 30pts
# 180-Day= 40pts
#
# If score >30, possible sensor drift occuring
#
# If score >=60, Likely sensor drift occuring
# Author: Colin Craig
########################################################################################################################
sub P_Stat_Test($$$){
	my %data=%{$_[0]}; #Hash of Hashes of Arrays keyed on 'Dates', and 'Data'.
	my @start_dates = @{$_[1]};
	my @end_dates = @{$_[2]};

	my $R = Statistics::R->new();
	use Data::Dumper;
	my @dates;
	my @pres_obs;
	my $six_months=259200;
	my $two_months=86400;
	my $four_months=172800;
	my $one_month=43200;
	my $month=int substr($start_dates[0],4,2);
	my @failed;
	my @passed;

	foreach my$top (keys %data){
		@pres_obs= @{$data{$top}{'Data'}};
		@dates=@{$data{$top}{'Dates'}};
		
		my $station=$top;
		my $min=Utilities::Time_Diff_int_min($start_dates[0],$end_dates[0]);
		#Ammount of past data.
		my $index_size=$#dates-$min;
		print $station."    ".$index_size."        ".$#dates."        ".$#pres_obs."\n";
		#next; 

		print "$station has $#pres_obs observations for specified time frame.\n"; 

			while($index_size<$#dates){ 
				my @new_obs_arr=();
				my @new_dates_arr=();
				my @results=();
				my $score=0;
				my @One_Month_Slope;my @Two_Month_Slope;my @Four_Month_Slope;my @Six_Month_Slope;
				print $index_size."\n";


				#Get past 30 days, run GLM, retrieve slope.
				if($index_size>.85*$one_month){
					if($index_size<$one_month){$one_month=$index_size;}
					for(my$q=$index_size;$q>=$index_size-$one_month;$q--){
						$new_obs_arr[$q]=$pres_obs[$q];
						$new_dates_arr[$q]=$dates[$q];
					}
					$R->send(q'y<-scan(text="'.qq'@new_obs_arr'.q'")');
					$R->send(q'x<-scan(text="'.qq'@new_dates_arr'.q'")');
					$R->send(q'model<-glm(y~x,family=gaussian)');
					$R->send(q'library(MASS)');
					@One_Month_Slope=$R->get(q'model$coeff');
					print "30-Day-Slope:   ".@One_Month_Slope->[0]->[1]."\n";
				}

				$R->stopR();
				$R = Statistics::R->new();
				
				#Get past 60 days, run GLM, retrieve slope.
				if($index_size>.85*$two_months){
					if($index_size<$two_months){$two_months=$index_size;}
					for(my$q=$index_size;$q>=$index_size-$two_months;$q--){
						$new_obs_arr[$q]=$pres_obs[$q];
						$new_dates_arr[$q]=$dates[$q];
					}
					$R->send(q'y<-scan(text="'.qq'@new_obs_arr'.q'")');
					$R->send(q'x<-scan(text="'.qq'@new_dates_arr'.q'")');
					$R->send(q'model<-glm(y~x,family=gaussian)');
					$R->send(q'library(MASS)');
					@Two_Month_Slope=$R->get(q'model$coeff');
					print "60-Day-Slope:   ".@Two_Month_Slope->[0]->[1]."\n";
				}
				$R->stopR();
				$R = Statistics::R->new();

				if($index_size>.85*$four_months){
					if($index_size<$four_months){$four_months=$index_size;}
					#Get past 120 days, run GLM, retrieve slope.
					for(my$q=$index_size;$q>=$index_size-$four_months;$q--){
						$new_obs_arr[$q]=$pres_obs[$q];
						$new_dates_arr[$q]=$dates[$q];
					}
					$R->send(q'y<-scan(text="'.qq'@new_obs_arr'.q'")');
					$R->send(q'x<-scan(text="'.qq'@new_dates_arr'.q'")');
					$R->send(q'model<-glm(y~x,family=gaussian)');
					$R->send(q'library(MASS)');
					@Four_Month_Slope=$R->get(q'model$coeff');
					print "120-Day-Slope:   ".@Four_Month_Slope->[0]->[1]."\n";
				}

				$R->stopR();
				$R = Statistics::R->new();

				#Get past 180 days, run GLM, retrieve slope.
				if($index_size>.85*$six_months){
					if($index_size<$six_months){$six_months=$index_size;}
					for(my$q=$index_size;$q>=$index_size-$six_months;$q--){
						$new_obs_arr[$q]=$pres_obs[$q];
						$new_dates_arr[$q]=$dates[$q];
					}
					$R->send(q'y<-scan(text="'.qq'@new_obs_arr'.q'")');
					$R->send(q'x<-scan(text="'.qq'@new_dates_arr'.q'")');
					$R->send(q'model<-glm(y~x,family=gaussian)');
					$R->send(q'library(MASS)');
					@Six_Month_Slope=$R->get(q'model$coeff');
					print "180-Day-Slope:   ".@Six_Month_Slope->[0]->[1]."\n";
				}

				#A slope of -5e-6 or less is sensitive enough to catch a 5% Yearly drift 
				#over the course of one month. Any less, and it may be too sensitive.
				#
				#-2.5e-6 threshold is used for 2,4,6 month periods. (summer months)
				#-2.5e-7 threshold is used for 2,4,6 month periods. (winter months)
				#
				#Winter months are given a more sensitive negative slope threshold since winter time 					#pressures are typically higher overall. 
				if($month==12 || ($month<=3 && $month>=1)){
					if((@One_Month_Slope->[0]->[1])<-0.0000005){$score=$score+10;}
					if((@Two_Month_Slope->[0]->[1])<-0.00000025){$score=$score+20;}
					if((@Four_Month_Slope->[0]->[1])<-0.00000025){$score=$score+30;}
					if((@Six_Month_Slope->[0]->[1])<-.00000025){$score=$score+40;}
					}
				else{
					if((@One_Month_Slope->[0]->[1])<-0.000005){$score=$score+10;}
					if((@Two_Month_Slope->[0]->[1])<-0.0000025){$score=$score+20;}
					if((@Four_Month_Slope->[0]->[1])<-0.0000025){$score=$score+30;}
					if((@Six_Month_Slope->[0]->[1])<-.0000025){$score=$score+40;}
					}

				if($score>=30){
					push(@failed,(4,$station,$dates[$index_size],"pres",$pres_obs[$index_size],-1));
					print $dates[$index_size]."    ".$pres_obs[$index_size]."\n";}
				else{
					push(@passed,(0,$station,$dates[$index_size],"pres",$pres_obs[$index_size],-1));}

				#
				print "SCORE:   $score\n";
				
				$index_size=$index_size+60;} ####ENDWHILE

			#my @this=$R->get(q'diff(x)');
			#print Dumper(@this);
			#$R->send(q'pdf("TEST.pdf",onefile=TRUE)');
			#$R->send(q'plot(model)');
			#$R->send(q'dev.off()');
			#$R->send(q'wd=getwd()');
			#my $wd=$R->get(q'wd');
			#print "\nPDF stored in $wd\n";
	}

return (\@passed,\@failed);
}
#############################################################################################################################
#Gets Pressure (minute) data.
#
#Author: Colin Craig
#############################################################################################################################
sub get_p_dat($$$$$){
        my $db          =$_[0];
        my $stations    =$_[1];
        my $parameters  =$_[2];
        my $start_date =$_[3];
        my $end_date   =$_[4];

	my $start=Utilities::Day_Subtract_int($start_date->[0]);
	my $end=$end_date->[0];
	my %out;
	print $start."\n";
	print $end."\n";
	#Get past 15 days inclusive of data.

	foreach my$station (@{$stations}){
		#print $station."\n";
		my $query = "SELECT station,DATE_FORMAT(ob,'%Y%m%d%H%i'),IFNULL(pres,'n') FROM hourly WHERE station = '$station' AND ob >= '$start' AND ob < '$end' AND obtype = 'O' ";

		my $result = $db->Query($query);
		my $row_count = $result->numrows;
		my @row = $result->FetchRow; #Removes Header Row. 
		my $counter=0;
		my @minutes=();
		my @newdates=();
		
		for(my$i=0;$i<$row_count;$i++){
	
		@row = $result->FetchRow;

		if($row[2] != 'n' && $row[2] != '0' && $row[2] != 'NULL'){
			$newdates[$counter] =  int $row[1];
			$minutes[$counter] = $row[2];
			$counter++;		}

			#if(($counter-1)>200000 && $minutes[($counter-1)]>0){
			#$minutes[$counter-1]=$minutes[$counter-1]-((($counter-1)-100000)/1440)*.08;
			#$minutes[$counter-1]=$minutes[$counter-1]-$minutes[$counter-1]*((($counter-1)-200000)/525600)*.06;
			#print $minutes[$counter-1]."      ".($minutes[$counter-1]*((($counter-1)-150000)/525600)*.05)."\n";
				#}
			
		}

		#print "$#minutes    $#newdates\n";
		$out{"$station"}={"Dates"=>\@newdates,"Data"=>\@minutes};
	}

	return (%out);

}




#############################################################################################################################
# Temperature Trend: This check is to look for erroneous spikes in data. Any spike will be flagged with a "Z" flag and
# subjected to the QC Score. 
#
# @param0 = Array of hourly data
# @param1 = Array of parameters
#
# @return = Array of failed/passed values
#############################################################################################################################



sub temperature_trend($$){
        my $dataRef             =$_[0];                 # hourly data
        my $parameterRef        =$_[1];                 # array of parameters 

        my @observation;                        	# stores a reference to an observation
	my @time;					# stores an observation time
	my $parameter = $parameterRef->[0]->[0];	# stores parameter
	
        my $station = $dataRef->[0]->[0];            	# stores the station in each observation
        my $ob_time;                            	# stores the observation time for each observation

        my $tempavg;                            # stores the temperature average values

        my $number_datarows = @{$dataRef};      # number of observations
	#print "Number of Datarows: ".$number_datarows."\n";

        my @passed;                             # stores observations which pass quality control
        my @failed;                             # stores observations which fail quality control
        my $flag_individually;

        for(my$j=0;$j<($number_datarows-6);$j++){
                $observation[$j] = $dataRef->[$j+3]->[3];
		$time[$j] = $dataRef->[$j+3]->[1];
                #print "Station: ".$station."\tP: ".$parameterRef->[0]->[0]."\tTime: ".$time[$j]."\tTemp: ".$observation[$j]."\n"; 
        }
	

	my $number_obs = @observation;
	#print "Number of Obs: ".$number_obs."\n";
	my @prevaverage; my @afteraverage; my @mean; my @low; my @high;

	for(my$i=0;$i<($number_obs-6);$i++){
		$prevaverage[$i] = ($observation[$i]+$observation[$i+1]+$observation[$i+2])/3;		# previous 3 minute average
		$afteraverage[$i] = ($observation[$i+4]+$observation[$i+5]+$observation[$i+6])/3;	# after 3 minute average
		$mean[$i] = ($prevaverage[$i]+$afteraverage[$i])/2;
		$low[$i] = 0.93*$mean[$i];
		$high[$i] = 1.07*$mean[$i];
		#print "Ob: ".$observation[$i+3]."\tLow: ".sprintf("%.3f",$low[$i])."\tHigh: ".sprintf("%.3f",$high[$i])."\n";

		if(($low[$i] > $observation[$i+3]) || ($high[$i] < $observation[$i+3])){
			 #print $parameter."\n";
			 my @missed = (4,$station,$time[$i+3],$parameter,$observation[$i+3],-1);
		 	 #print @missed;
			 #exit;
			 push(@failed,\@missed);
		
		} else{
			#print $parameter."\n";
			my @hit = (0,$station,$time[$i+3],$parameter);
			push(@passed,\@hit);
		}
		
		
		
	}
	#print @passed."\n";
	return(\@passed,\@failed);
}

############################################################################################################################
# Radiation Trend: This helps determine if there is sensor in the drift. It should be noted that if a value is flagged for
# failing the check, a "D" flag will be placed. However, the D flag will not be used in QC Score purposes
#
# @param0 = Current year observations
# @param1 = Previous year observations
# @param2 = Array of parameters
#
# @return = Array of failed and passed observations
###########################################################################################################################



sub radiation_trend($$$$){
        my $dataRef      =$_[0];                # hourly data
        my $prevyearRef  =$_[1];                # previous years data
	my $alldataRef	 =$_[2];		# all hourly data
        my $parameterRef =$_[3];                # array of parameters

        my @observation;                        # stores a reference to an observation
        my @observation_average;
        my @observation_mean;

        my @prevob;                             # the previos year's observation
        my @prevob_average;
        my @prevob_mean;

        my $station = $dataRef->[0]->[0];       # stores the station in each observation
        my $ob_time;                            # stores the observation time for each observation
        my $sravg;                              # stores the sravg values
        my $paravg;                             # stores the paravg values

	my $parameter = $parameterRef->[0]->[0];

        my $number_datarows = @{$dataRef};      # number of observations
        #print "Number of Datarows: $number_datarows\n";
        my $number_elements = @{$parameterRef}; # number of values per observation
	my $all_datarows    = @{$alldataRef};
	#print "Number of obs: ".$all_datarows."\n";
	#exit;

        my $numberDays = $number_datarows/5;    # number of days used in study
        #print "\nNumber of Days: ".$numberDays."\n\n";

        my @passed;                             # stores observations which pass quality control
        my @failed;                             # stores observations which fail quality control
        my $flag_individually;
        #------------------------------------------------------------------------------------
        # Loop through a single observation
        #------------------------------------------------------------------------------------
        for(my$j=0;$j<$numberDays;$j++){

                $observation[$j] = ($dataRef->[$j*5]->[3])+($dataRef->[($j*5)+1]->[3])+($dataRef->[($j*5)+2]->[3])+($dataRef->[($j*5)+3]->[3])+($dataRef->[($j*5)+4]->[3]);     #obtain observations of SR/PAR per day
                $observation_average[$j] = $observation[$j]/5;
                $prevob[$j] = ($prevyearRef->[$j*5]->[3])+($prevyearRef->[($j*5)+1]->[3])+($prevyearRef->[($j*5)+2]->[3])+($prevyearRef->[($j*5)+3]->[3])+($prevyearRef->[($j*5)+4]->[3]);      #obtain observations of SR/PAR per day
                $prevob_average[$j] = $prevob[$j]/5;
                #print "Observation Average: ".$observation_average[$j]."\n";

        }
        for(my$i=2;$i<($numberDays-2);$i++){
                $observation_mean[$i] = ($observation_average[$i-2] + $observation_average[$i-1] + $observation_average[$i]+ $observation_average[$i+1] + $observation_average[$i+2])/5;
                $prevob_mean[$i] = ($prevob_average[$i-2] + $prevob_average[$i-1] + $prevob_average[$i]+ $prevob_average[$i+1] + $prevob_average[$i+2])/5;    
                #print "Ob. Mean: ".$observation_mean[$i]."\n";
        }

        my $numberObs = @observation_mean;
        my $TotalSum = 0;
        my $PrevSum = 0;
        #------------------------------------------------------------------------------------
        # Sum up all averages
        #------------------------------------------------------------------------------------
        for(my$k=0;$k<$numberObs;$k++){
        $TotalSum = $TotalSum + $observation_mean[$k];
        $PrevSum = $PrevSum + $prevob_mean[$k];
        }
        #print "Total Sum:    ".$TotalSum."\n";
        #print "Previous Sum: ".$PrevSum."\n";
        #my $AverageDay = $TotalSum/$numberObs;
	my $AverageDay = 200;
        my $PrevAverageDay = $PrevSum/$numberObs;
        my $Difference = $PrevAverageDay - $AverageDay;
	my $Ratio = $AverageDay/$PrevAverageDay;
        #print "\nAverage Day(Prev. Year): ".sprintf("%.2f",$PrevAverageDay)."\n";
        #print "Average Day(Current):    ".sprintf("%.2f",$AverageDay)."\n";
        #print "Difference:              ".sprintf("%.2f",$Difference)."\n";
	#print "Ratio:                   ".sprintf("%.2f",$Ratio)."\n";


        #------------------------------------------------------------------------------------
        # Calculate Absolute Error 
        #------------------------------------------------------------------------------------
        my @anomaly;    my @prevanomaly;
        my $TotalAnomaly = 0;
        my $TotalPrevAnomaly = 0;
        for(my$i=0;$i<$numberObs;$i++){
        $anomaly[$i] = abs($observation_mean[$i] - $AverageDay);
        $prevanomaly[$i] = abs($prevob_mean[$i] - $PrevAverageDay);
        }
        for(my$j=0;$j<$numberObs;$j++){
        $TotalAnomaly = $TotalAnomaly + $anomaly[$j];
        #print "Total Anomaly: ".$anomaly[$j]."\n";
        $TotalPrevAnomaly = $TotalPrevAnomaly + $prevanomaly[$j];
        }
        #print "Obs: $numberObs\n";
        #print "Total Anomaly: $TotalAnomaly\n";
        my $AverageAnomaly = $TotalAnomaly/$numberObs;
        my $PrevAverageAnomaly = $TotalPrevAnomaly/$numberObs;
        #print "\nAverage Anomaly(Prev. Year): ".sprintf("%.2f",$PrevAverageAnomaly)."\n";
        #print "Average Anomaly(Current):    ".sprintf("%.2f",$AverageAnomaly)."\n";

        if($Ratio < 0.94){
		for(my$i=0;$i<$all_datarows;$i++){
	        my @missed = (4,$station,$alldataRef->[$i]->[1],$parameter,$alldataRef->[$i]->[3],-1);
		push(@failed,\@missed);
		}
        }
	else{
		for(my$i=0;$i<$numberObs;$i++){
		
                my @hit = (0,$station,$alldataRef->[$i]->[1],$parameter);
		push(@passed,\@hit);
		}
	}


	return(\@passed,\@failed);

}

#################################################################################################
# Data Setup to ingest into Run subroutine
#
# @param0 = Connect to correct database 
# @param1 = Array of stations
# @param2 = Array of parameters
# @param3 = Array of start times
# @param4 = Array of end times
#
#################################################################################################

sub data_setup($$$$$){

        my $db          =$_[0];
        my $stations    =$_[1];
        my $parameters  =$_[2];
        my $start_times =$_[3];
        my $end_times   =$_[4];

        my $parameterRef = $parameters->[0]->[0];
       # print $start_times->[0]."\n";
       # print "Parameter: ".$parameterRef."\n";
        my @output;
        my $query;

        if(($parameterRef eq 'sr') or ($parameterRef eq 'par') or ($parameterRef eq 'sravg') or ($parameterRef eq 'paravg')){
        my $query=radiation($stations,$parameterRef,$start_times,$end_times);
	#print "QUERY: ".$query."\n";
        my $queryResult = $db->Query($query) or die "\nYOU FOOL!\n\n";
        my $queryCount = $queryResult->numrows;
        #print "Number of Rows: $queryCount\n";

        my @queryRow;
        #----------------------------------------------------------------------------------------
        # Loop through a single observation
        #----------------------------------------------------------------------------------------
                for(my $i=0;$i<$queryCount;$i++){
                        @queryRow = $queryResult->FetchRow;
                        $queryRow[1] =~ s/-|:| //g;
                        #print $queryRow[3]."\n";
                        $output[$i] = [@queryRow];
                        #print "Value: ".$output[$i]->[3]."\n";
                }
        #print "Success!\n";
        #exit;}
	}
        elsif($parameterRef eq 'temp'){
        my $query=temperature($stations,$parameterRef,$start_times,$end_times);
	print $query."\n";
	#exit;
	#print "QUERY: ".$query."\n";
        my $queryResult = $db->Query($query) or die "\nYOU FOOL!\n\n";
        my $queryCount = $queryResult->numrows;
        #print "Number of Rows: $queryCount\n";

        my @queryRow;
        #----------------------------------------------------------------------------------------
        # Loop through a single observation
        #----------------------------------------------------------------------------------------
                for(my $i=0;$i<$queryCount;$i++){
                        @queryRow = $queryResult->FetchRow;
                        $queryRow[1] =~ s/-|:| //g;
                        #print $queryRow[3]."\n";
                        $output[$i] = [@queryRow];
                        #print "Value: ".$output[$i]->[3]."\n";
                }
        #print "Success!\n";
        #exit;
	}
	
	
        else{
        print "\nParameter not valid for trend check at this time...\n";
        }

        #return(\@output,\@output2);
        #print "Test: ".$output[223]->[3]."\n";
        #print "Test: ".$output[224]->[3]."\n";
        return(\@output);
}


#################################################################################################
# Previous Year Data Setup to ingest into Run subroutine
#
# @param0 = Connect to correct database 
# @param1 = Array of stations
# @param2 = Array of parameters
# @param3 = Array of start times
# @param4 = Array of end times
#
#################################################################################################

sub data_setup_prevyear($$$$$){

        my $db          =$_[0];
        my $stations    =$_[1];
        my $parameters  =$_[2];
        my $start_times =$_[3];
        my $end_times   =$_[4];

        my $parameterRef = $parameters->[0]->[0];
        #print "Parameter: ".$parameterRef."\n";
        my @output;
        if(($parameterRef eq 'sr') or ($parameterRef eq 'par') or ($parameterRef eq 'sravg') or ($parameterRef eq 'paravg')){
        my $query = prev_radiation($stations,$parameterRef,$start_times,$end_times);
        my $queryResult = $db->Query($query) or die "\nYOU FOOL!\n\n";
        my $queryCount = $queryResult->numrows;
        #print "\nNumber of hourly observations found: ".$queryCount."\n";
        my @queryRow;
        #----------------------------------------------------------------------------------------
        # Loop through a single observation
        #----------------------------------------------------------------------------------------
                for(my $i=0;$i<$queryCount;$i++){
                        @queryRow = $queryResult->FetchRow;
                        $queryRow[1] =~ s/-|:| //g;
                        #print $queryRow[3]."\n";
                        $output[$i] = [@queryRow];
                        #print "Value: ".$output[$i]->[3]."\n";
                }
        #print "Success!\n";
        #exit;
        }
        else{
        print "\nParameter not valid for trend check at this time...\n"
        }
        #return(\@output,\@output2);
        #print "Test: ".$output[223]->[3]."\n";
        #print "Test: ".$output[224]->[3]."\n";
        return(\@output);
}

##################################################################################################
# Data Setup to pull all radiation data
#
# @param0 = Connect to correct database
# @param1 = Array of stations
# @param2 = Array of parameters
# @param3 = Array of start dates
# @param4 = Array of end dates
##################################################################################################
sub data_setup_all($$$$$){

        my $db          =$_[0];
        my $stations    =$_[1];
        my $parameters  =$_[2];
        my $start_times =$_[3];
        my $end_times   =$_[4];

        my $parameterRef = $parameters->[0]->[0];
        #print "Parameter: ".$parameterRef."\n";
        my @output;
        if(($parameterRef eq 'sr') or ($parameterRef eq 'par') or ($parameterRef eq 'sravg') or ($parameterRef eq 'paravg')){
        my $query = radiation_all($stations,$parameterRef,$start_times,$end_times);
        my $queryResult = $db->Query($query) or die "\nYOU FOOL!\n\n";
        my $queryCount = $queryResult->numrows;
        #print "\nNumber of hourly observations found: ".$queryCount."\n";
        my @queryRow;
        #----------------------------------------------------------------------------------------
        # Loop through a single observation
        #----------------------------------------------------------------------------------------
                for(my $i=0;$i<$queryCount;$i++){
                        @queryRow = $queryResult->FetchRow;
                        $queryRow[1] =~ s/-|:| //g;
                        #print $queryRow[3]."\n";
                        $output[$i] = [@queryRow];
                        #print "Value: ".$output[$i]->[3]."\n";
                }
        #print "Success!\n";
        #exit;
        }
        else{
        print "\nParameter not valid for trend check at this time...\n"
        }
        #return(\@output,\@output2);
        #print "Test: ".$output[223]->[3]."\n";
        #print "Test: ".$output[224]->[3]."\n";
        return(\@output);


}


##################################################################################################
# Query to pull radiation data
#
# @param0 = Array of stations
# @param1 = Array of parameters
# @param2 = Array of start times
# @param3 = Array of end times
#
##################################################################################################

sub radiation($$$$){
        my $stationRef   = $_[0];       # reference to array of stations
        my $parameterRef = $_[1];       # reference to array of parameters
        my $startRef     = $_[2];       # reference to array of start times
        my $endRef       = $_[3];       # reference to array of end times

        my $numberOfStations = @{$stationRef};
        my @observationArray;

        my $qc;
# if an end time is selected
        if($endRef!=undef){

                for(my$i=0;$i<$numberOfStations;$i++){

                        $observationArray[$i] = "(station = '".$stationRef->[$i]."' 
                        AND (HOUR(ob) = '10' or HOUR(ob) = '11' or HOUR(ob) = '12' or HOUR(ob) = '13' or HOUR(ob) ='14') AND MINUTE(ob) = '00' AND
                        ob >= '".$startRef->[$i]."' AND ob <= '".$endRef->[$i]."' AND obtype = 'H')";
                        #print $observationArray[$i]."\n";
                        #exit;
                }

        }

        return "SELECT station,ob,obtype,sravg,paravg FROM hourly WHERE ".Utilities::seperated_list(\@observationArray," OR ","");

}

##################################################################################################
# Query to pull radiation data
#
# @param0 = Array of stations
# @param1 = Array of parameters
# @param2 = Array of start times
# @param3 = Array of end times
#
##################################################################################################

sub prev_radiation($$$$){
        my $stationRef   = $_[0];       # reference to array of stations
        my $parameterRef = $_[1];       # reference to array of parameters
        my $startRef     = $_[2];       # reference to array of start times
        my $endRef       = $_[3];       # reference to array of end times

        my $newstart;
        my $newend;

        $newstart = $startRef->[0] - 10000000000;
        $newend = $endRef->[0] - 10000000000;

        my $numberOfStations = @{$stationRef};
        my @observationArray;

        my $qc;
# if an end time is selected
        if($endRef!=undef){

                for(my$i=0;$i<$numberOfStations;$i++){

                        $observationArray[$i] = "(station = '".$stationRef->[$i]."' 
                        AND (HOUR(ob) = '10' or HOUR(ob) = '11' or HOUR(ob) = '12' or HOUR(ob) = '13' or HOUR(ob) ='14') AND MINUTE(ob) = '00' AND
                        ob >= '".$newstart."' AND ob <= '".$newend."' AND obtype = 'H')";
                        #print $observationArray[$i]."\n";
                        #exit;
                }

        }

        return "SELECT station,ob,obtype,sravg,paravg FROM hourly WHERE ".Utilities::seperated_list(\@observationArray," OR ","");

}

##################################################################################################
# Query to pull all radiation data
#
# @param0 = Array of stations
# @param1 = Array of parameters
# @param2 = Array of start times
# @param3 = Array of end times
#
##################################################################################################

sub radiation_all($$$$){

        my $stationRef   = $_[0];       # reference to array of stations
        my $parameterRef = $_[1];       # reference to array of parameters
        my $startRef     = $_[2];       # reference to array of start times
        my $endRef       = $_[3];       # reference to array of end times

        my $numberOfStations = @{$stationRef};
        my @observationArray;

        my $qc;
# if an end time is selected
        if($endRef!=undef){

                for(my$i=0;$i<$numberOfStations;$i++){

                        $observationArray[$i] = "(station = '".$stationRef->[$i]."' 
                        AND (HOUR(ob) = '10' or HOUR(ob) = '11' or HOUR(ob) = '12' or HOUR(ob) = '13' or HOUR(ob) ='14') AND MINUTE(ob) = '00' AND
                        ob >= '".$startRef->[$i]."' AND ob <= '".$endRef->[$i]."' AND obtype = 'O')";
                        #print $observationArray[$i]."\n";
                        #exit;
                }

        }

        return "SELECT station,ob,obtype,sr,par FROM hourly WHERE ".Utilities::seperated_list(\@observationArray," OR ","");

}

##################################################################################################
# Query to pull temperature data
#
# @param0 = Array of stations
# @param1 = Array of parameters
# @param2 = Array of start times
# @param3 = Array of end times
#
##################################################################################################

sub temperature($$$$){
        my $stationRef   = $_[0];       # reference to array of stations
        my $parameterRef = $_[1];       # reference to array of parameters
        my $startRef     = $_[2];       # reference to array of start times
        my $endRef       = $_[3];       # reference to array of end times

	#print "Start Time: ".$startRef->[0]."\n";
	#print "End Time: ".$endRef->[0]."\n";
	

	my @start_times;
	my @end_times;
        my $numberOfStations = @{$stationRef};
        my @observationArray;

        my $newstart;
        my $newend;
        my @days_in_month       = (31,28,31,30,31,30,31,31,30,31,30,31);
        my $year                = substr($startRef->[0],0,4);
        my $start_month         = substr($startRef->[0],4,2); 
        my $start_day           = substr($startRef->[0],6,2);
        my $start_hour          = substr($startRef->[0],8,2);
        my $start_minutes       = substr($startRef->[0],10,2);

        my $end_month           = substr($endRef->[0],4,2);
        my $end_day             = substr($endRef->[0],6,2);
        my $end_hour            = substr($endRef->[0],8,2);
        my $end_minutes         = substr($endRef->[0],10,2);

        my $start_time; my $end_time;   my $data;       my @failed;

        $start_minutes = $start_minutes - 6;
	print "Start Minutes: ".$start_minutes."\n";
	#if ($start_minutes < 10){$start_minutes = "0".$start_minutes;}	
        if ($start_minutes < 0){
                $start_hour--;
		print "Start Hour: ".$start_hour."\n";
                if($start_hour < 0){
                        $start_day--;
			print "Start Day: ".$start_day."\n";
			if ($start_day < 10){$start_day = "0".$start_day;}
                        if ($start_day < 1){
                                $start_month--;
                                if($start_month < 1){
                                        $year--;
                                        $start_month = $start_month+12;
					if ($start_month < 10){$start_month = "0".$start_month;}
					
                                }
                                $start_day = $start_day + $days_in_month[$start_month-1];
				
                        }
                        $start_hour = $start_hour+24;
				
                }
                $start_minutes = $start_minutes + 60;
		
		
		if ($start_hour < 10){$start_hour = "0".$start_hour;}
		if ($start_minutes < 10){$start_minutes = "0".$start_minutes;}
        }
        $end_minutes = $end_minutes + 6;
	#print "End Minutes: ".$end_minutes."\n";
	if ($end_minutes < 10){$end_minutes = "0".$end_minutes;}
	if ($end_minutes > 59){
                $end_hour++;
		#print "End Hour: ".$end_hour."\n";
                if ($end_hour > 23){
                        $end_day++;
                        if($end_day > $days_in_month[$end_month-1]){
                                $end_month++;
                                if($end_month > 12){
                                        $year++;
                                        $end_month = $end_month-12;
					
                                }
                               $end_day = $end_day - $days_in_month[$end_month-1];
		        }
                        $end_hour = $end_hour - 24;
		}
                $end_minutes = $end_minutes - 60;
		if ($end_month < 10){$end_month = "0".$end_month;}
		if ($end_day < 10){$end_day = "0".$end_day;}
		if ($end_hour < 10){$end_hour = "0".$end_hour;}
		if ($end_minutes < 10){$end_minutes = "0".$end_minutes;}
        }
        $start_time     = $year.$start_month.$start_day.$start_hour.$start_minutes."00";
        $end_time       = $year.$end_month.$end_day.$end_hour.$end_minutes."00";

	
	#print "New Start Time: ".$start_time."\n";
	#print "New End Time: ".$end_time."\n";
	#exit;

        $newstart = $startRef->[0];
        $newend = $endRef->[0];

	#print "New Start: ".$newstart."\n";
	#print "New End: ".$newend."\n";
	#exit;
        my $qc;
# if an end time is selected
        if($endRef!=undef){

                for(my$i=0;$i<$numberOfStations;$i++){
                        $observationArray[$i] = "(station = '".$stationRef->[$i]."' 
                        AND ob >= '".$start_time."' AND ob <= '".$end_time."' AND obtype = 'O')";
                        #print $observationArray[$i]."\n";
                        #exit;
                }

        }

        return "SELECT station,ob,obtype,temp FROM hourly WHERE ".Utilities::seperated_list(\@observationArray," OR ","");


}

################################################################################################### 
# Prints information about the given ranges to the screen.
#
# @param0 - reference to data
# @param1 - string representation of flag (e.g. "R" or "B")
################################################################################################### 
sub print_data($$$){

        my $data = $_[0];
        my $flag = $_[1];
        my $type = $_[2];

        my $count = @{$data};
        my $current;
	
        my $date;
        my $length;

	print $type."\n";
        if($type!=0){

                for(my$i=0;$i<$count;$i++){

                        $current = $data->[$i];
			$date = substr($current->[2],0,4)."-".substr($current->[2],4,2)."-".substr($current->[2],6,2)." ".substr($current->[2],8,2).":".substr($current->[2],10,2).":".substr($current->[2],12,2);

                        print $flag.$current->[0]."  ";
                        print $current->[1]."  ";
                        print $date."   ";
                        print $type->{$current->[1]}."    ";

                        $length = length $current->[3];

                        if($length < 11){ print $current->[3]; for(my$i=0;$i<11-$length;$i++){ print " ";}}
                        else { print $current->[3]." ";}

                        print substr($current->[4],0,6)."         ";
                        print substr($current->[5],0,6)."       ";
                        print substr($current->[6],0,6)."\n";
                }
        } else {
                for(my$i=0;$i<$count;$i++){

                        $current = $data->[$i];
                        $date = substr($current->[2],0,4)."-".substr($current->[2],4,2)."-".substr($current->[2],6,2)." ".substr($current->[2],8,2).":".substr($current->[2],10,2).":".substr($current->[2],12,2);

                        print $flag.$current->[0]."  ";
                        print $current->[1]."  ";
                        print $date."   ";
                        print $type->{$current->[1]}."    ";

                        $length = length $current->[3];

                        if($length < 11){ print $current->[3]; for(my$i=0;$i<11-$length;$i++){ print " ";}}
                        else { print $current->[3]." ";}

                        print substr($current->[4],0,6)."         ";
                        print substr($current->[5],0,6)."       ";
                        print substr($current->[6],0,6)."\n";
                }
        } 
}

1;





