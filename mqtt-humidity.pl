#!/usr/bin/perl
use strict;
use warnings;
use JSON qw(decode_json);
use Net::MQTT::Simple;
use Getopt::Long 'HelpMessage';
my($temperature,$humidity,$fahrenheit);
my $dehumidifier="off";

GetOptions(
  'hostname=s' => \ my $hostname,
  'port=i'   => \(my $port = '1883'),
  'threshold=i'   => \(my $threshold = '60'),
  'help'     =>   sub { HelpMessage(0) },
) or HelpMessage(1);

HelpMessage(1) unless $hostname;

mqtt_interact();

exit(0);

sub mqtt_interact {
  my $mqtt = Net::MQTT::Simple->new("$hostname:$port");
  $mqtt->publish('MQTT-Perl-Monitor' => 'Humidity monitor has subscribed and listenting...');
  $mqtt->run(
    "zigbee2mqtt/Temperature Humidity Sensor" => sub {
       my ($topic, $message) = @_;
       my $decoded = decode_json($message);
       $humidity = $decoded->{'humidity'};
       $temperature = $decoded->{'temperature'};
       $fahrenheit = (9 * $temperature/5) + 32;
       print "Temp C = $temperature : Temp F = $fahrenheit : Humidity = $humidity\n";
       if ($humidity >= $threshold && $dehumidifier eq "off") {
         $mqtt->publish('zigbee2mqtt/Smart Outlet/set' => '{ "state": "ON" }');
         $dehumidifier="on"
       }
       if ($humidity < $threshold && $dehumidifier eq "on") {
         $mqtt->publish('zigbee2mqtt/Smart Outlet/set' => '{ "state": "OFF" }');
         $dehumidifier="off"
       }
    },
  );
}

=head1 NAME

mqtt-humidity.pl - Monitor MQTT queue humidity and take action by turning on or off smart outlet

=head1 SYNOPSIS

  --hostname,-h   Hostname or IP address of MQTT host
  --port,-p       Port for MQTT (defaults to default 1883)
  --threshold,-t  Threshold for humidity (defaults to 60)
  --help,-h       Print this help

Example:

mqtt-humidity.pl -ho 10.43.26.170 -p 1883 -t 65

=head1 VERSION

0.01

=cut

