#!/usr/bin/perl
use strict;
use warnings;
use JSON qw(decode_json);
use Net::MQTT::Simple;
use Data::Dumper;
use Getopt::Std;
my($temperature,$humidity,$fahrenheit);
my $dehumidifier="off";

my %options=();
getopts("i:p:h", \%options);

sub printhelp {
  print "mqtt-example.pl -i <mqtthostip> -p <port>  -h <help>\n";
  exit 0;
}

if (defined $options{h}) {
  printhelp();
}

if (defined $options{i} && defined $options{p}) {
  my $mqtt = Net::MQTT::Simple->new("$options{i}:$options{p}");
  $mqtt->publish('MQTT-Perl-Monitor' => 'Humidity monitor has subscribed and listenting...');
  $mqtt->run(
    "zigbee2mqtt/Temperature Humidity Sensor" => sub {
       my ($topic, $message) = @_;
       my $decoded = decode_json($message);
       # print Dumper($decoded);
       $humidity = $decoded->{'humidity'};
       $temperature = $decoded->{'temperature'};
       $fahrenheit = (9 * $temperature/5) + 32;
       print "Temp C = $temperature : Temp F = $fahrenheit : Humidity = $humidity\n";
       if ($humidity >= 60 && $dehumidifier eq "off") {
         $mqtt->publish('zigbee2mqtt/Smart Outlet/set' => '{ "state": "ON" }');
         $dehumidifier="on"
       }
       if ($humidity < 60 && $dehumidifier eq "on") {
         $mqtt->publish('zigbee2mqtt/Smart Outlet/set' => '{ "state": "OFF" }');
         $dehumidifier="off"
       }
    },
  );
} else {
  printhelp();
}
exit;
