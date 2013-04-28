<?php
#require_once('/home/www/html/dynamic_scripts/cronos/functions.php');

//Finds the nearest station given a latitude, and a longitude. 
function find_nearest_station($lat,$lon){
// now do distance query
// this formula uses the Great Circle Distance Formula method

$query= "SELECT * , 3963 * ACOS( SIN( $lat / 57.2958 ) * SIN( lat / 57.2958 ) + COS( $lat / 57.2958 ) * COS( lat / 57.2958 ) * COS( (
lon / 57.2958
) - (  $lon / 57.2958 ) ) ) AS distance
FROM cronos.statmeta
HAVING distance <=100
AND hasdata =1
AND TYPE = 'ECONET' 
ORDER BY distance ASC
LIMIT 0,1";

$results = mysql_query($query) or MailError(q,y,$_SERVER['REQUEST_URI'],__LINE__,$query);

// Retrieve first row/first col (Station name)
$nearest_station_ECONet= mysql_result($results,0,0);
$dist_ECONet=mysql_result($results,0,"distance");

$query= "SELECT * , 3963 * ACOS( SIN( $lat / 57.2958 ) * SIN( lat / 57.2958 ) + COS( $lat / 57.2958 ) * COS( lat / 57.2958 ) * COS( (
lon / 57.2958
) - (  $lon / 57.2958 ) ) ) AS distance
FROM cronos.statmeta
HAVING distance <=100
AND hasdata =1
AND TYPE = 'ASOS' 
ORDER BY distance ASC
LIMIT 0,1";
$results = mysql_query($query) or MailError(q,y,$_SERVER['REQUEST_URI'],__LINE__,$query);
$nearest_station_ASOS= mysql_result($results,0,0);
$dist_ASOS=mysql_result($results,0,"distance");

if($dist_ASOS>$dist_ECONet){$nearest_station_ASOS=$nearest_station_ECONet;}
$var=array($nearest_station_ECONet,$nearest_station_ASOS);
return $var;}


// Input a City, ST or street address to find its lat/lon
function getLatLonFromAddress($address) {
// URL encode the search string
$q    = urlencode($address);
// Google Maps API key
$key  = 'ABQIAAAA0BIlltj4hqXEx0HhjaMfAxRyqzClQTNiLXQmSpWrmK3wX-IJAhTQ2S0IgsN4ozeGnKoozO1vhUPoKA';
// URL.  Format is csv or xml.
$url  = "http://maps.google.com/maps/geo?q=$q&output=csv&key=$key";

// Get output from the constructed URL
// Expecting only one line of output
$geocode_results = file_get_contents($url);
list($status,$accuracy,$lat,$lon) = explode(',',$geocode_results);

$loc['lat'] = $lat;
$loc['lon'] = $lon;
return $loc;}

/*
*This Function retrieves XML format data from the NOAA NDFD data from NOAA SOAP server,
*and then places the Max, Min, and Average temperatures into associative arrays in the format:
*$Array['Day x']= Temperature for that day.
*Next, it sums up hourly temp data, and produced average temp for each forecast day; This is then 
*stored in an array. All of the data from this function is stored in array $Var and returned. 
*/

//If enough time, I would like to rewrite this procedure,
//and offload the XML parsing to a recursive function to optimize this process...
//-Colin

function getNDFD($lat,$lon){
date_default_timezone_set('UTC'); //Awesome.
$start_time= date("Y-m-d")."T".date("H:i:s"); //Current Date/time in UTC
$end_time= date("Y-m-d",strtotime('+3 days'))."T".date("H:i:s"); //3 days into future. 



$url="http://graphical.weather.gov/xml/SOAP_server/ndfdXMLclient.php?whichClient=NDFDgen&lat=$lat&lon=$lon+&listLatLon=&lat1=&lon1=&lat2=&lon2=&resolutionSub=&listLat1=&listLon1=&listLat2=&listLon2=&resolutionList=&endPoint1Lat=&endPoint1Lon=&endPoint2Lat=&endPoint2Lon=&listEndPoint1Lat=&listEndPoint1Lon=&listEndPoint2Lat=&listEndPoint2Lon=&zipCodeList=&listZipCodeList=&centerPointLat=&centerPointLon=&distanceLat=&distanceLon=&resolutionSquare=&listCenterPointLat=&listCenterPointLon=&listDistanceLat=&listDistanceLon=&listResolutionSquare=&citiesLevel=&listCitiesLevel=&sector=&gmlListLatLon=&featureType=&requestedTime=&startTime=&endTime=&compType=&propertyName=&product=time-series&begin=$start_time&end=$end_time&Unit=e&maxt=maxt&mint=mint&temp=temp&qpf=qpf&sky=sky&pop12=pop12&wx=wx&Submit=Submit";

$doc= new DOMDocument();
$doc->load($url);

$root = $doc->documentElement;              // get the first child node (the root)
$elems = $root->getElementsByTagName("temperature")->item(0);      // gets all elements ("temperature") of root, at item(0) (Max Temps) 

$Max_Temps= array("Day 0"=> 0,"Day 1"=> 0, "Day 2" => 0, "Day 3" => 0);
$Min_Temps= array("Day 0"=> 0,"Day 1"=> 0, "Day 2" => 0, "Day 3" => 0);
$Avg_Temps= array("Day 0"=>0,"Day 1"=> 0, "Day 2" => 0, "Day 3" => 0);
$QPF=array("Day 0"=> 0,"Day 1"=> 0, "Day 2" => 0, "Day 3" => 0);
$CC= array("Day 0"=> 0,"Day 1"=> 0, "Day 2" => 0, "Day 3" => 0);
$POP= array("Day 0"=> 0,"Day 1"=> 0, "Day 2" => 0, "Day 3" => 0);
$wx_coverage= array("Day 0"=> 0,"Day 1"=> 0, "Day 2" => 0, "Day 3" => 0);
$wx_intensity= array("Day 0"=> 0,"Day 1"=> 0, "Day 2" => 0, "Day 3" => 0);
$wx_type= array("Day 0"=> 0,"Day 1"=> 0, "Day 2" => 0, "Day 3" => 0);

#Get Maximum Temps
#OKAY.

$Max_Temps["Day 0"]= $elems->getElementsByTagName('value')->item(0)->nodeValue;
$Max_Temps["Day 1"]= $elems->getElementsByTagName('value')->item(1)->nodeValue;
$Max_Temps["Day 2"]= $elems->getElementsByTagName('value')->item(2)->nodeValue;
$Max_Temps["Day 3"]= $elems->getElementsByTagName('value')->item(3)->nodeValue;



$elems = $root->getElementsByTagName("temperature")->item(1);      // gets all elements ("temperature") of root, at item(0) (Max Temps) 

#Get Minimum Temps.
#OKAY. 
#print date("H"); #Current Hour

# If current hour is less than 8z get current days forecasted min temp. 
if(date("H")<8){
	$Min_Temps["Day 0"]= $elems->getElementsByTagName('value')->item(0)->nodeValue;
	$Min_Temps["Day 1"]= $elems->getElementsByTagName('value')->item(1)->nodeValue;
	$Min_Temps["Day 2"]= $elems->getElementsByTagName('value')->item(2)->nodeValue;
	$Min_Temps["Day 3"]= $elems->getElementsByTagName('value')->item(3)->nodeValue;}
else{
	$Min_Temps["Day 1"]= $elems->getElementsByTagName('value')->item(0)->nodeValue;
	$Min_Temps["Day 2"]= $elems->getElementsByTagName('value')->item(1)->nodeValue;
	$Min_Temps["Day 3"]= $elems->getElementsByTagName('value')->item(2)->nodeValue;}

$elems = $root->getElementsByTagName("temperature")->item(2);
$Hourly_Day1=array();
$Hourly_Day2=array();
$Hourly_Day3=array();
$CC_Day1=array();$CC_Day2=array();$CC_Day3=array();
$POP_Day1=array();$POP_Day2=array();$POP_Day3=array();

#Get Hourly Temps
for($i=0;$i<=6;$i++){
$Hourly_Day1[$i]=$elems->getElementsByTagName('value')->item($i)->nodeValue; //sum up first forecast day (Temps)
$Hourly_Day2[$i]=$elems->getElementsByTagName('value')->item($i+7)->nodeValue;//sum up second forecast day
$Hourly_Day3[$i]=$elems->getElementsByTagName('value')->item($i+14)->nodeValue;}//sum up third forecast day 

#Get QPF data
$elems = $root->getElementsByTagName("precipitation")->item(0);
for($i=0;$i<=3;$i++){
	$QPF["Day 1"]=number_format($QPF["Day 1"]+($elems->getElementsByTagName('value')->item($i)->nodeValue),2);
	$QPF["Day 2"]=number_format($QPF["Day 2"]+($elems->getElementsByTagName('value')->item($i+4)->nodeValue),2);
	$QPF["Day 3"]=number_format($QPF["Day 3"]+($elems->getElementsByTagName('value')->item($i+8)->nodeValue),2);}

$Avg_Temps['Day 1']=number_format(array_sum($Hourly_Day1)/(sizeof($Hourly_Day1)),2);
$Avg_Temps['Day 2']=number_format(array_sum($Hourly_Day2)/(sizeof($Hourly_Day2)),2);
$Avg_Temps['Day 3']=number_format(array_sum($Hourly_Day3)/(sizeof($Hourly_Day3)),2);

#Get Cloud Cover
$elems = $root->getElementsByTagName("cloud-amount")->item(0);
for($i=0;$i<=6;$i++){
	$CC_Day1[$i]=number_format(($elems->getElementsByTagName('value')->item($i)->nodeValue),2);
	$CC_Day2[$i]=number_format(($elems->getElementsByTagName('value')->item($i+7)->nodeValue),2);
	$CC_Day3[$i]=number_format(($elems->getElementsByTagName('value')->item($i+14)->nodeValue),2);}
$CC['Day 1']=number_format(array_sum($CC_Day1)/(sizeof($CC_Day1)),2);
$CC['Day 2']=number_format(array_sum($CC_Day2)/(sizeof($CC_Day2)),2);
$CC['Day 3']=number_format(array_sum($CC_Day3)/(sizeof($CC_Day3)),2);

#Get Prob. of Precip in next 12 hours.
$elems = $root->getElementsByTagName("probability-of-precipitation")->item(0);
for($i=0;$i<=2;$i++){
	$POP_Day1[$i]=number_format(($elems->getElementsByTagName('value')->item($i)->nodeValue),2);
	$POP_Day2[$i]=number_format(($elems->getElementsByTagName('value')->item($i+2)->nodeValue),2);
	$POP_Day3[$i]=number_format(($elems->getElementsByTagName('value')->item($i+4)->nodeValue),2);}
$POP['Day 1']=round(number_format(array_sum($POP_Day1)/(sizeof($POP_Day1)),2),0);
$POP['Day 2']=round(number_format(array_sum($POP_Day2)/(sizeof($POP_Day2)),2),0);
$POP['Day 3']=round(number_format(array_sum($POP_Day3)/(sizeof($POP_Day3)),2),0);

#Get Weather information. 

$xmlstr = file_get_contents($url);
$xml = simplexml_load_string($xmlstr);
$xml_weather = $xml->data->parameters->weather;
#print_r($xml_weather);
$count=count($xml->data->parameters->temperature->value);

for($z=0;$z<$count;$z++){
	$wx_coverage["Day $z"] = $xml_weather->{'weather-conditions'}[$z]->value->attributes()->{'coverage'};
	$wx_intensity["Day $z"]= $xml_weather->{'weather-conditions'}[$z]->value->attributes()->{'intensity'};
	$wx_type["Day $z"]= $xml_weather->{'weather-conditions'}[$z]->value->attributes()->{'weather-type'};
	}

#print $wx_type['Day 1'];


/*
print nl2br("\n\n[All Temps are in F, Precip in inches]");
print nl2br("\n\nDaily Max Temps [Future].");
print nl2br("\nCurrent Day: ").$Max_Temps['Day 0'];
print nl2br("\nCurrent Day +1: ").$Max_Temps['Day 1'];
print nl2br("\nCurrent Day +2: ").$Max_Temps['Day 2'];
print nl2br("\nCurrent Day +3: ").$Max_Temps['Day 3'];
print nl2br("\n\nDaily Min Temps [Future].");
print nl2br("\nCurrent Day +1: ").$Min_Temps['Day 1'];
print nl2br("\nCurrent Day +2: ").$Min_Temps['Day 2'];
print nl2br("\nCurrent Day +3: ").$Min_Temps['Day 3'];
//print nl2br("\n Time: $start_time \n Future Time: $end_time");
print nl2br("\n\nAverage Temps [Future].");
print nl2br("\nCurrent Day +1: ").$Avg_Temps['Day 1'];
print nl2br("\nCurrent Day +2: ").$Avg_Temps['Day 2'];
print nl2br("\nCurrent Day +3: ").$Avg_Temps['Day 3'];
print nl2br("\n\nQPF [Future].");
print nl2br("\nCurrent Day +1: ").$QPF['Day 1'];
print nl2br("\nCurrent Day +2: ").$QPF['Day 2'];
print nl2br("\nCurrent Day +3: ").$QPF['Day 3'];*/




#All arrays are keyed on ['Day 0'] through ['Day 3']

$NDFD_results = array($Max_Temps,$Min_Temps,$Avg_Temps,$QPF,$CC,$POP,$wx_coverage,$wx_intensity,$wx_type);
return $NDFD_results;
}

//Gets past data...
function getPastData($station_ECONet,$station_ASOS){
date_default_timezone_set('America/New_York'); //Awesome.
$start_date=date("Y-m-d-00");
$end_date=date("Y-m-d-H");
$station1=$station_ECONet;
$station2=$station_ASOS;


$Max_Temps= array("Day 0"=> 0,"Day -1"=> 0, "Day -2" => 0, "Day -3" => 0);
$Min_Temps= array("Day 0"=> 0,"Day -1"=> 0, "Day -2" => 0, "Day -3" => 0);
$Avg_Temps= array("Day 0"=> 0,"Day -1"=> 0, "Day -2" => 0, "Day -3" => 0);
$Soil_Temps= array("Day 0"=> 0,"Day -1"=> 0, "Day -2" => 0, "Day -3" => 0);
$Precip= array("Day 0"=> 0,"Day -1"=> 0, "Day -2" => 0, "Day -3" => 0);

/*Get Soil Type*/
$query="SELECT station, soil_texture as soil FROM cronos.statmeta WHERE station = '$station_ECONet' ";
$results = mysql_query($query) or MailError(q,y,$_SERVER['REQUEST_URI'],__LINE__,$query);
$soil_type=mysql_result($results,0,"soil");



for($i=0;$i<=3;$i++){
//gets soil temp (avg), precip (sum), avg_temp,max_temp, and min_temp
$query="SELECT station, DATE_FORMAT( ob, '%Y-%m-%d-%H' ) , ((9/5)*(AVG( st ))+32) AS st, SUM( precip ) as precip FROM cronos.hourly WHERE station = '$station_ECONet' AND ob >= '$start_date' AND ob < '$end_date' AND obtype = 'H'";
$results = mysql_query($query) or MailError(q,y,$_SERVER['REQUEST_URI'],__LINE__,$query);

$Soil_Temps["Day -$i"]= number_format(mysql_result($results,0,"st"),2);
$Precip["Day -$i"]= number_format(mysql_result($results,0,"precip"),2);

	if($i==0){
		$Soil_Temps["Day 0"]= number_format(mysql_result($results,0,"st"),2);
		$Precip["Day 0"]= number_format(mysql_result($results,0,"precip"),2);
		$end_date=$start_date;
		$start_date=date("Y-m-d-00",time() - 86400 * ($i+1));} //start date = previous start date -1 day
	else{
		$start_date=date("Y-m-d-00",time() - 86400 * ($i+1)); //start date = previous start date -1 day
		$end_date=date("Y-m-d-00",time() - 86400 * ($i));}

$start_date=date("Y-m-d-",time() - 86400 * ($i+1))."00"; //start date = previous start date -1 day
$end_date=date("Y-m-d-",time() - 86400 * ($i))."00";} //End date = previous start date.

$start_date=date("Y-m-d-00"); //Reset Date...
$end_date=date("Y-m-d-H");


$query="SELECT station, DATE_FORMAT( ob, '%Y-%m-%d-%H' ),(( 9 /5 ) * temp +32) AS avg_temp, MAX((( 9 /5 ) * temp +32)) as max_temp, MIN((( 9 /5 ) * temp +32)) as min_temp FROM cronos.hourly WHERE station = '$station_ASOS' AND ob >= '$start_date' AND ob < '$end_date'";
$results = mysql_query($query) or MailError(q,y,$_SERVER['REQUEST_URI'],__LINE__,$query);

if(mysql_result($results,0,"max_temp")==0 or mysql_result($results,0,"max_temp")=='NULL'){$station_ASOS=$station_ECONet;}



for($i=0;$i<=3;$i++){
//gets soil temp (avg), precip (sum), avg_temp,max_temp, and min_temp
#print nl2br("\n$start_date \n $end_date \n");
$query="SELECT station, DATE_FORMAT( ob, '%Y-%m-%d-%H' ),(( 9 /5 ) * temp +32) AS avg_temp, MAX((( 9 /5 ) * temp +32)) as max_temp, MIN((( 9 /5 ) * temp +32)) as min_temp FROM cronos.hourly WHERE station = '$station_ASOS' AND ob >= '$start_date' AND ob < '$end_date'";
$results = mysql_query($query) or MailError(q,y,$_SERVER['REQUEST_URI'],__LINE__,$query);

$Max_Temps["Day -$i"]= number_format(mysql_result($results,0,"max_temp"),2);
$Min_Temps["Day -$i"]= number_format(mysql_result($results,0,"min_temp"),2);
$Avg_Temps["Day -$i"]= number_format(mysql_result($results,0,"avg_temp"),2);

	if($i==0){
		$Max_Temps["Day 0"]= number_format(mysql_result($results,0,"max_temp"),2);
		$Min_Temps["Day 0"]= number_format(mysql_result($results,0,"min_temp"),2);
		$Avg_Temps["Day 0"]= number_format(mysql_result($results,0,"avg_temp"),2);
		$end_date=$start_date;
		$start_date=date("Y-m-d-00",time() - 86400 * ($i+1));} //start date = previous start date -1 day
	else{
		$start_date=date("Y-m-d-00",time() - 86400 * ($i+1)); //start date = previous start date -1 day
		$end_date=date("Y-m-d-00",time() - 86400 * ($i));}
} //End date = previous start date.

/*
print nl2br("\nCurrent Precip: ").$Precip['Day 0'];
print nl2br("\nCurrent MaxT: ").$Max_Temps['Day 0'];
print nl2br("\nCurrent MinT: ").$Min_Temps['Day 0'];
print nl2br("\nCurrent AvgT: ").$Avg_Temps['Day 0'];
print nl2br("\nCurrent SoilT: ").$Soil_Temps['Day 0'];

print nl2br("\n\nDaily Max Temps [Past].");
print nl2br("\nCurrent Day -1: ").$Max_Temps['Day -1'];
print nl2br("\nCurrent Day -2: ").$Max_Temps['Day -2'];
print nl2br("\nCurrent Day -3: ").$Max_Temps['Day -3'];
print nl2br("\n\nDaily Min Temps [Past].");
print nl2br("\nCurrent Day -1: ").$Min_Temps['Day -1'];
print nl2br("\nCurrent Day -2: ").$Min_Temps['Day -2'];
print nl2br("\nCurrent Day -3: ").$Min_Temps['Day -3'];
print nl2br("\n\nAverage Temps [Past].");
print nl2br("\nCurrent Day -1: ").$Avg_Temps['Day -1'];
print nl2br("\nCurrent Day -2: ").$Avg_Temps['Day -2'];
print nl2br("\nCurrent Day -3: ").$Avg_Temps['Day -3'];
print nl2br("\n\nSoil Temps [Past].");
print nl2br("\nCurrent Day -1: ").$Soil_Temps['Day -1'];
print nl2br("\nCurrent Day -2: ").$Soil_Temps['Day -2'];
print nl2br("\nCurrent Day -3: ").$Soil_Temps['Day -3'];
print nl2br("\n\n Accumulated Precipitation for past 3 days: ");
print nl2br("\nCurrent Day -1: ").$Precip['Day -1'];
print nl2br("\nCurrent Day -2: ").$Precip['Day -2'];
print nl2br("\nCurrent Day -3: ").$Precip['Day -3'];*/


$Var=array($Max_Temps,$Min_Temps,$Avg_Temps,$Soil_Temps,$Precip,$soil_type);

return $Var;}

function Parse_WRF_Soil_Output($lat,$lon){
$date =date("Y-m-d H:00:00");

$wrf_model = getWRFModelOutput_soil($lat,$lon);

$Day_Sums_1= array();
$Day_Sums_2=array();
$Day_Sums_3=array();
$Soil_Temps= array("Day 1"=> 0, "Day 2" => 0, "Day 3" => 0);


###############################################
#Sums up the next 3 days of soil temperature forecasts
#from in-house WRF model.
###############################################
for($j=1;$j<=3;$j++){
for($i=1;$i<=24;$i++){
if($j==1){$Day_Sums_1[$i-1]=$wrf_model[$date]['st10'];}
if($j==2){$Day_Sums_2[$i-1]=$wrf_model[$date]['st10'];}
if($j==3){if($wrf_model[$date]['st10']!=NULL){$Day_Sums_3[$i-1]=$wrf_model[$date]['st10'];}else{$i=24;}}//If no more data for remaining hours, quit.

$date=date("Y-m-d H:00:00",time() + 3600 * ($i)+(86400*($j-1)));}} #Add an hour.

#Sum-> Average->Convert from Kelvin to F

#$Soil_Temps['Day 1']=(array_sum($Day_Sums_1)/(sizeof($Day_Sums_1)));
#$Soil_Temps['Day 2']=(array_sum($Day_Sums_2)/(sizeof($Day_Sums_2)));
#$Soil_Temps['Day 3']=(array_sum($Day_Sums_3)/(sizeof($Day_Sums_3)));


$Soil_Temps['Day 1']=number_format((1.8*((array_sum($Day_Sums_1)/(sizeof($Day_Sums_1)))-273.15))+32,2);
$Soil_Temps['Day 2']=number_format((1.8*((array_sum($Day_Sums_2)/(sizeof($Day_Sums_2)))-273.15))+32,2);
$Soil_Temps['Day 3']=number_format((1.8*((array_sum($Day_Sums_3)/(sizeof($Day_Sums_3)))-273.15))+32,2);

#print nl2br("\n\n Forecasted Soil Temps: "."\nCurrent Day +1: ".$Soil_Temps['Day 1']."\nCurrent Day +2: ".$Soil_Temps['Day 2']."\nCurrent Day +3: ".$Soil_Temps['Day 3']);
return $Soil_Temps;
}


function disease_Threshold_Check($station,$turf_type,$grass_type,$soil_type,$soil_age,$NDFD_results, $ECONet_results, $WRF_Soil){

$start_date=date("Y-m-d-00");
$end_date=date("Y-m-d-H");
$Disease_Forecast= array();


$Disease_Forecast['Day 1']=array();
$Disease_Forecast['Day 2']=array();
$Disease_Forecast['Day 3']=array();


/*NDFD_Max_Temps and NDFD_Min_Temps contains ("Day 1"=> value, "Day 2" => value, "Day 3=> value")*/
/*ie. NDFD_Max_Temps['Day 1'] = 55 , NDFD_Min_Temps['Day 1'] = 31 or NDFD_Avg_Temps['Day 1'] = 44*/

$NDFD_Max_Temps=$NDFD_results[0];
$NDFD_Min_Temps=$NDFD_results[1];
$NDFD_Avg_Temps=$NDFD_results[2];
$NDFD_Precip=$NDFD_results[3];

/*Contains results for the past 3 days of ECONet observations for station: */
/*ex) $ECONet_Max_Temps['Day -1']=Max temp for first past day.*/
$ECONet_Max_Temps=$ECONet_results[0];
$ECONet_Min_Temps=$ECONet_results[1];
$ECONet_Avg_Temps=$ECONet_results[2];
$ECONet_Soil_Temps=$ECONet_results[3];
$ECONet_Precip=$ECONet_results[4];
$ECONet_soil_type=$ECONet_results[5];

$Soil_Forecast=$WRF_Soil;

//Set up 2D-Arrays to store disease activity for each Grass Type.

$Creeping_Bentgrass=array('Day -3'=>array(),'Day -2'=>array(),'Day -1'=>array(),'Day 0'=>array(),'Day 1'=>array(),'Day 2'=>array(),'Day 3'=>array());
$Annual_Bluegrass=array('Day -3'=>array(),'Day -2'=>array(),'Day -1'=>array(),'Day 0'=>array(),'Day 1'=>array(),'Day 2'=>array(),'Day 3'=>array());
$Tall_Fescue=array('Day -3'=>array(),'Day -2'=>array(),'Day -1'=>array(),'Day 0'=>array(),'Day 1'=>array(),'Day 2'=>array(),'Day 3'=>array());
$Perennial_Ryegrass=array('Day -3'=>array(),'Day -2'=>array(),'Day -1'=>array(),'Day 0'=>array(),'Day 1'=>array(),'Day 2'=>array(),'Day 3'=>array());
$Kentucky_Bluegrass=array('Day -3'=>array(),'Day -2'=>array(),'Day -1'=>array(),'Day 0'=>array(),'Day 1'=>array(),'Day 2'=>array(),'Day 3'=>array());
$Bermudagrass=array('Day -3'=>array(),'Day -2'=>array(),'Day -1'=>array(),'Day 0'=>array(),'Day 1'=>array(),'Day 2'=>array(),'Day 3'=>array());
$St_Augustinegrass=array('Day -3'=>array(),'Day -2'=>array(),'Day -1'=>array(),'Day 0'=>array(),'Day 1'=>array(),'Day 2'=>array(),'Day 3'=>array());
$Zoysiagrass=array('Day -3'=>array(),'Day -2'=>array(),'Day -1'=>array(),'Day 0'=>array(),'Day 1'=>array(),'Day 2'=>array(),'Day 3'=>array());
$Centipedegrass=array('Day -3'=>array(),'Day -2'=>array(),'Day -1'=>array(),'Day 0'=>array(),'Day 1'=>array(),'Day 2'=>array(),'Day 3'=>array());

if($Current_Max_T>$NDFD_Max_Temps['Day 1']){$NDFD_Max_Temps['Day 1']=$Current_Max_T;} #If max Temp has been reached, use



//Get Forecast Outlook for Current Day, and next 3 days.

for($i=0;$i<=3;$i++){
	if($i==0){
	/* CURRENT DAY CHECK*/
	/*MAX TEMP CHECK*/
		if($ECONet_Max_Temps['Day 0']>90){
			foreach ($turf_type as $t){if($t=='greens'){array_push($Creeping_Bentgrass["Day $i"],"Anthracnose");}}}
		elseif($ECONet_Max_Temps['Day 0']>75){foreach ($turf_type as $t){if($t=='greens'){array_push($Annual_Bluegrass["Day $i"],"Anthracnose");}}}
		
		elseif($ECONet_Max_Temps['Day 0']<65){
			foreach ($turf_type as $t){if($t=='greens' or $t=='fairways' or $t=='tees'){array_push($Creeping_Bentgrass["Day $i"],"Microdochium Patch");}}
			foreach ($turf_type as $t){if($t=='greens' or $t=='fairways' or $t=='tees'){array_push($Annual_Bluegrass["Day $i"],"Microdochium Patch");}}
			foreach ($turf_type as $t){if($t=='greens' or $t=='fairways' or $t=='tees'){array_push($Bermudagrass["Day $i"],"Microdochium Patch");}}
					  if($Current_Max_T>45){
						array_push($Creeping_Bentgrass["Day $i"],"Yellow Patch");
						array_push($Annual_Bluegrass["Day $i"],"Yellow Patch");}}
						
		/*Soil_T Check*/
		if($ECONet_Soil_Temps['Day 0']>65){array_push($Creeping_Bentgrass["Day $i"],"Summer Patch");
						    array_push($Annual_Bluegrass["Day $i"],"Summer Patch");
						    array_push($Kentucky_Bluegrass["Day $i"],"Summer Patch");}
		if($ECONet_Soil_Temps['Day 0']<80){
					if($ECONet_Soil_Temps['Day 0']>50 && $ECONet_Soil_Temps['Day 0']<70){
						    array_push($Zoysiagrass["Day $i"],"Large Patch");
						    array_push($St_Augustinegrass["Day $i"],"Large Patch");
						    array_push($Centipedegrass["Day $i"],"Large Patch");
						    if($soil_age=='lt10'){
						    	foreach ($turf_type as $t){
						    		if($t=='greens'){
						    			if($soil_type=='sand'){array_push($Creeping_Bentgrass["Day $i"],"Pythium root dysfunction");}}}
						    		}
						    	}
					if($ECONet_Soil_Temps['Day 0']>60){
						    array_push($Bermudagrass["Day $i"],"Spring Dead Spot");
						    array_push($Zoysiagrass["Day $i"],"Spring Dead Spot");}
					if($ECONet_Soil_Temps['Day 0']<65 && $ECONet_Soil_Temps['Day 0']>55){
						    if($soil_type=='sand'){
						    foreach ($turf_type as $t){if($t=='greens'){array_push($Creeping_Bentgrass["Day $i"],"Fairy Ring");}}
						    foreach ($turf_type as $t){if($t=='greens'){array_push($Bermudagrass["Day $i"],"Fairy Ring");}}}
						    		}
						    }
		/*Min_T Check*/
		if($ECONet_Min_Temps['Day 0']>65){array_push($Annual_Bluegrass["Day $i"],"Pythium Blight");
					array_push($Perennial_Ryegrass["Day $i"],"Pythium Blight");
					array_push($Kentucky_Bluegrass["Day $i"],"Pythium Blight");
					array_push($Tall_Fescue["Day $i"],"Pythium Blight");}
		elseif($ECONet_Min_Temps['Day 0']>60){
					array_push($Annual_Bluegrass["Day $i"],"Brown Patch");
					array_push($Creeping_Bentgrass["Day $i"],"Brown Patch");
					array_push($Tall_Fescue["Day $i"],"Brown Patch");
					array_push($Perennial_Ryegrass["Day $i"],"Brown Patch");
					array_push($Kentucky_Bluegrass["Day $i"],"Brown Patch");
					}
		elseif($ECONet_Min_Temps['Day 0']>50){
					array_push($Annual_Bluegrass["Day $i"],"Dollar Spot");
					array_push($Creeping_Bentgrass["Day $i"],"Dollar Spot");
					array_push($Perennial_Ryegrass["Day $i"],"Dollar Spot");
					array_push($Kentucky_Bluegrass["Day $i"],"Dollar Spot");
					array_push($Zoysiagrass["Day $i"],"Dollar Spot");}
		elseif($ECONet_Min_Temps['Day 0']>35){
					array_push($Creeping_Bentgrass["Day $i"],"Red Leaf Spot");}
					
		if($ECONet_Min_Temps['Day 0']<60){array_push($Bermudagrass["Day $i"],"Pythium Blight");}
		
		/*Avg T Check*/
		if($ECONet_Avg_Temps['Day 0']<85 && $ECONet_Avg_Temps['Day 0']>50){
			if($ECONet_Avg_Temps['Day 0']>80){
					if($soil_age=='lt5'){
						array_push($Tall_Fescue["Day $i"],"Gray Leaf Spot");
						array_push($St_Augustinegrass["Day $i"],"Gray Leaf Spot");
						array_push($Perennial_Ryegrass["Day $i"],"Gray Leaf Spot");}
						}
			if($ECONet_Avg_Temps['Day 0']<70){
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fairways' or $t=='tees'){
								array_push($Creeping_Bentgrass["Day $i"],"Red Thread");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fairways' or $t=='tees'){
								array_push($Annual_Bluegrass["Day $i"],"Red Thread");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fairways' or $t=='tees'){
								array_push($Perennial_Ryegrass["Day $i"],"Red Thread");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fairways' or $t=='tees'){
								array_push($Kentucky_Bluegrass["Day $i"],"Red Thread");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fairways' or $t=='tees'){
								array_push($Tall_Fescue["Day $i"],"Red Thread");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fields'){
								array_push($Kentucky_Bluegrass["Day $i"],"Rust");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fields'){
								array_push($Perennial_Ryegrass["Day $i"],"Rust");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fields'){
								array_push($Tall_Fescue["Day $i"],"Rust");}}
					}
			if($ECONet_Avg_Temps['Day 0']>65){
					foreach ($turf_type as $t){if($t=='greens'){array_push($Creeping_Bentgrass["Day $i"],"Copper Spot");}}
					}

					}
		/*END CURRENT DAY CHECK*/			
			}
			
		/*FUTURE DAY CHECKS*/
		/*MAX TEMP CHECK*/
		if($NDFD_Max_Temps["Day $i"]>90){array_push($Creeping_Bentgrass["Day $i"],"Anthracnose");}
		elseif($NDFD_Max_Temps["Day $i"]>75){array_push($Annual_Bluegrass["Day $i"],"Anthracnose");}
		elseif($NDFD_Max_Temps["Day $i"]<65){
			foreach ($turf_type as $t){if($t=='greens' or $t=='fairways' or $t=='tees'){array_push($Creeping_Bentgrass["Day $i"],"Microdochium Patch");}}
			foreach ($turf_type as $t){if($t=='greens' or $t=='fairways' or $t=='tees'){array_push($Annual_Bluegrass["Day $i"],"Microdochium Patch");}}
			foreach ($turf_type as $t){if($t=='greens' or $t=='fairways' or $t=='tees'){array_push($Bermudagrass["Day $i"],"Microdochium Patch");}}
					  
			if($NDFD_Max_Temps["Day $i"]>45){
					array_push($Creeping_Bentgrass["Day $i"],"Yellow Patch");
					array_push($Annual_Bluegrass["Day $i"],"Yellow Patch");}
					}
						
		/*Soil_T Check*/
		if($Soil_Forecast["Day $i"]>65){array_push($Creeping_Bentgrass["Day $i"],"Summer Patch");
						    array_push($Annual_Bluegrass["Day $i"],"Summer Patch");
						    array_push($Kentucky_Bluegrass["Day $i"],"Summer Patch");}
		if($Soil_Forecast["Day $i"]<80){
					if($Soil_Forecast["Day $i"]>50 && $Soil_Forecast["Day $i"]<70){
						    array_push($Zoysiagrass["Day $i"],"Large Patch");
						    array_push($St_Augustinegrass["Day $i"],"Large Patch");
						    array_push($Centipedegrass["Day $i"],"Large Patch");
						    if($soil_age=='lt10'){
						    	foreach ($turf_type as $t){
						    		if($t=='greens'){
						    			if($soil_type=='sand'){array_push($Creeping_Bentgrass["Day $i"],"Pythium root dysfunction");}}}
						    			}
						   	 }
					if($Soil_Forecast["Day $i"]>60){
						    array_push($Bermudagrass["Day $i"],"Spring Dead Spot");
						    array_push($Zoysiagrass["Day $i"],"Spring Dead Spot");}
					if($Soil_Forecast["Day $i"]<65 && $Soil_Forecast["Day $i"]>55){
						    if($soil_type=='sand'){
						    foreach ($turf_type as $t){if($t=='greens'){array_push($Creeping_Bentgrass["Day $i"],"Fairy Ring");}}
						    foreach ($turf_type as $t){if($t=='greens'){array_push($Bermudagrass["Day $i"],"Fairy Ring");}}}
						    	}
						    }
		/*Min_T Check*/
		if($NDFD_Min_Temps["Day $i"]>65){
					array_push($Annual_Bluegrass["Day $i"],"Pythium Blight");
					array_push($Perennial_Ryegrass["Day $i"],"Pythium Blight");
					array_push($Kentucky_Bluegrass["Day $i"],"Pythium Blight");
					array_push($Tall_Fescue["Day $i"],"Pythium Blight");}
		elseif($NDFD_Min_Temps["Day $i"]>60){
					array_push($Annual_Bluegrass["Day $i"],"Brown Patch");
					array_push($Creeping_Bentgrass["Day $i"],"Brown Patch");
					array_push($Tall_Fescue["Day $i"],"Brown Patch");
					array_push($Perennial_Ryegrass["Day $i"],"Brown Patch");
					array_push($Kentucky_Bluegrass["Day $i"],"Brown Patch");}
		elseif($NDFD_Min_Temps["Day $i"]>50){
					array_push($Annual_Bluegrass["Day $i"],"Dollar Spot");
					array_push($Creeping_Bentgrass["Day $i"],"Dollar Spot");
					array_push($Perennial_Ryegrass["Day $i"],"Dollar Spot");
					array_push($Kentucky_Bluegrass["Day $i"],"Dollar Spot");
					array_push($Zoysiagrass["Day $i"],"Dollar Spot");}
		elseif($NDFD_Min_Temps["Day $i"]>35){
					array_push($Creeping_Bentgrass["Day $i"],"Red Leaf Spot");}
					
		if($NDFD_Min_Temps["Day $i"]<60){array_push($Bermudagrass["Day $i"],"Pythium Blight");}
		
		/*Avg T Check*/
		if($i==1){
		if($ECONet_Avg_Temps["Day $i"]<85 && $ECONet_Avg_Temps["Day $i"]>50){
			if($ECONet_Avg_Temps["Day $i"]>80){
					if($soil_age=='lt5'){
						array_push($Tall_Fescue["Day $i"],"Gray Leaf Spot");
						array_push($St_Augustinegrass["Day $i"],"Gray Leaf Spot");
						array_push($Perennial_Ryegrass["Day $i"],"Gray Leaf Spot");}
							}
			if($ECONet_Avg_Temps["Day $i"]<70){
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fairways' or $t=='tees'){
								array_push($Creeping_Bentgrass["Day $i"],"Red Thread");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fairways' or $t=='tees'){
								array_push($Annual_Bluegrass["Day $i"],"Red Thread");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fairways' or $t=='tees'){
								array_push($Perennial_Ryegrass["Day $i"],"Red Thread");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fairways' or $t=='tees'){
								array_push($Kentucky_Bluegrass["Day $i"],"Red Thread");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fairways' or $t=='tees'){
								array_push($Tall_Fescue["Day $i"],"Red Thread");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fields'){
								array_push($Kentucky_Bluegrass["Day $i"],"Rust");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fields'){
								array_push($Perennial_Ryegrass["Day $i"],"Rust");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fields'){
								array_push($Tall_Fescue["Day $i"],"Rust");}}
					}
			if($ECONet_Avg_Temps["Day $i"]>65){
					foreach ($turf_type as $t){if($t=='greens'){array_push($Creeping_Bentgrass["Day $i"],"Copper Spot");}}
					}
					}}


			}
			
	/*Get Disease information for past 3 days*/
	for($i=-3;$i<0;$i++){
		/*MAX TEMP CHECK*/
		if($ECONet_Max_Temps["Day $i"]>90){
			foreach ($turf_type as $t){if($t=='greens'){array_push($Creeping_Bentgrass["Day $i"],"Anthracnose");}}}
		elseif($ECONet_Max_Temps["Day $i"]>75){foreach ($turf_type as $t){if($t=='greens'){array_push($Annual_Bluegrass["Day $i"],"Anthracnose");}}}
		elseif($ECONet_Max_Temps["Day $i"]<65){
			foreach ($turf_type as $t){if($t=='greens' or $t=='fairways' or $t=='tees'){array_push($Creeping_Bentgrass["Day $i"],"Microdochium Patch");}}
			foreach ($turf_type as $t){if($t=='greens' or $t=='fairways' or $t=='tees'){array_push($Annual_Bluegrass["Day $i"],"Microdochium Patch");}}
			foreach ($turf_type as $t){if($t=='greens' or $t=='fairways' or $t=='tees'){array_push($Bermudagrass["Day $i"],"Microdochium Patch");}}
					  if($ECONet_Max_Temps["Day $i"]>45){
						array_push($Creeping_Bentgrass["Day $i"],"Yellow Patch");
						array_push($Annual_Bluegrass["Day $i"],"Yellow Patch");}}
						
		/*Soil_T Check*/
		if($ECONet_Soil_Temps["Day $i"]>65){array_push($Creeping_Bentgrass["Day $i"],"Summer Patch");
						    array_push($Annual_Bluegrass["Day $i"],"Summer Patch");
						    array_push($Kentucky_Bluegrass["Day $i"],"Summer Patch");}
		if($ECONet_Soil_Temps["Day $i"]<80){
					if($Soil_Forecast["Day $i"]>50 && $Soil_Forecast["Day $i"]<70){
						    array_push($Zoysiagrass["Day $i"],"Large Patch");
						    array_push($St_Augustinegrass["Day $i"],"Large Patch");
						    array_push($Centipedegrass["Day $i"],"Large Patch");
						    if($soil_age=='lt10'){
						    	foreach ($turf_type as $t){
						    		if($t=='greens'){
						    			if($soil_type=='sand'){array_push($Creeping_Bentgrass["Day $i"],"Pythium root dysfunction");}}}
						    		}
						    	}
					if($Soil_Forecast["Day $i"]>60){
						    array_push($Bermudagrass["Day $i"],"Spring Dead Spot");
						    array_push($Zoysiagrass["Day $i"],"Spring Dead Spot");}
					if($Soil_Forecast["Day $i"]<65 && $Soil_Forecast["Day $i"]>55){
						    if($soil_type=='sand'){
						    foreach ($turf_type as $t){if($t=='greens'){array_push($Creeping_Bentgrass["Day $i"],"Fairy Ring");}}
						    foreach ($turf_type as $t){if($t=='greens'){array_push($Bermudagrass["Day $i"],"Fairy Ring");}}}
						    	}
						    }
		/*Min_T Check*/
		if($ECONet_Min_Temps["Day $i"]>65){
					array_push($Annual_Bluegrass["Day $i"],"Pythium Blight");
					array_push($Perennial_Ryegrass["Day $i"],"Pythium Blight");
					array_push($Kentucky_Bluegrass["Day $i"],"Pythium Blight");
					array_push($Tall_Fescue["Day $i"],"Pythium Blight");}
		elseif($ECONet_Min_Temps["Day $i"]>60){
					array_push($Annual_Bluegrass["Day $i"],"Brown Patch");
					array_push($Creeping_Bentgrass["Day $i"],"Brown Patch");
					array_push($Tall_Fescue["Day $i"],"Brown Patch");
					array_push($Perennial_Ryegrass["Day $i"],"Brown Patch");
					array_push($Kentucky_Bluegrass["Day $i"],"Brown Patch");}
		elseif($ECONet_Min_Temps["Day $i"]>50){
					array_push($Annual_Bluegrass["Day $i"],"Dollar Spot");
					array_push($Creeping_Bentgrass["Day $i"],"Dollar Spot");
					array_push($Perennial_Ryegrass["Day $i"],"Dollar Spot");
					array_push($Kentucky_Bluegrass["Day $i"],"Dollar Spot");
					array_push($Zoysiagrass["Day $i"],"Dollar Spot");}
		elseif($ECONet_Min_Temps["Day $i"]>35){
					array_push($Creeping_Bentgrass["Day $i"],"Red Leaf Spot");}
					
		if($ECONet_Min_Temps["Day $i"]<60){array_push($Bermudagrass["Day $i"],"Pythium Blight");}
		
		/*Avg T Check*/
		if($ECONet_Avg_Temps["Day $i"]<85 && $ECONet_Avg_Temps['Day -1']>50){
			if($ECONet_Avg_Temps["Day $i"]>80){
					if($soil_age=='lt5'){
						array_push($Tall_Fescue["Day $i"],"Gray Leaf Spot");
						array_push($St_Augustinegrass["Day $i"],"Gray Leaf Spot");
						array_push($Perennial_Ryegrass["Day $i"],"Gray Leaf Spot");}
						}
			if($ECONet_Avg_Temps["Day $i"]<70){
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fairways' or $t=='tees'){
								array_push($Creeping_Bentgrass["Day $i"],"Red Thread");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fairways' or $t=='tees'){
								array_push($Annual_Bluegrass["Day $i"],"Red Thread");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fairways' or $t=='tees'){
								array_push($Perennial_Ryegrass["Day $i"],"Red Thread");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fairways' or $t=='tees'){
								array_push($Tall_Fescue["Day $i"],"Red Thread");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fairways' or $t=='tees'){
								array_push($Kentucky_Bluegrass["Day $i"],"Red Thread");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fields'){
								array_push($Kentucky_Bluegrass["Day $i"],"Rust");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fields'){
								array_push($Perennial_Ryegrass["Day $i"],"Rust");}}
				foreach ($turf_type as $t){if($t=='landscapes' or $t=='fields'){
								array_push($Tall_Fescue["Day $i"],"Rust");}}
					}
			if($ECONet_Avg_Temps["Day $i"]>65){
					foreach ($turf_type as $t){if($t=='greens'){array_push($Creeping_Bentgrass["Day $i"],"Copper Spot");}}
					}
					}
	
	
	
	
	} 
	/*END PAST CHECK*/
			
			
			
	/*Push only requested grass types onto output array.*/			
	$var=array();
	
	foreach ($grass_type as $g){
		if($g =='Creeping Bentgrass'){array_push($var,$Creeping_Bentgrass);}
		if($g=='Annual Bluegrass'){array_push($var,$Annual_Bluegrass);}
		if($g=='Tall Fescue'){array_push($var,$Tall_Fescue);}
		if($g=='Perennial Ryegrass'){array_push($var,$Perennial_Ryegrass);}
		if($g=='Kentucky Bluegrass'){array_push($var,$Kentucky_Bluegrass);}
		if($g=='St. Augustinegrass'){array_push($var,$St_Augustinegrass);}
		if($g=='Bermudagrass'){array_push($var,$Bermudagrass);}
		if($g=='Zoysiagrass'){array_push($var,$Zoysiagrass);}
		if($g=='Centipedegrass'){array_push($var,$Centipedegrass);}
	}
	
	
	
return $var;} 

function getMyTimeDiff($t1,$t2)
{
	$a1 = explode(":",$t1);
	$a2 = explode(":",$t2);
	$time1 = (($a1[0]*60*60)+($a1[1]*60)+($a1[2]));
	$time2 = (($a2[0]*60*60)+($a2[1]*60)+($a2[2]));
	$diff = abs($time1-$time2);
	$hours = floor($diff/(60*60));
	$mins = floor(($diff-($hours*60*60))/(60));
	$secs = floor(($diff-(($hours*60*60)+($mins*60))));
	$result = $hours.":".$mins.":".$secs;
	return $result;
}



?>
