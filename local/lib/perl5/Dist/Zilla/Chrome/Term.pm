package Dist::Zilla::Chrome::Term;
{
  $Dist::Zilla::Chrome::Term::VERSION = '5.006';
}
use Moose;
# ABSTRACT: chrome used for terminal-based interaction


use Dist::Zilla::Types qw(OneZero);
use Log::Dispatchouli 1.102220;

use namespace::autoclean;

has logger => (
  is  => 'ro',
  isa => 'Log::Dispatchouli',
  init_arg => undef,
  writer   => '_set_logger',
  lazy_build => 1,
);

sub _build_logger {
  my $self = shift;
  my $layer = sprintf(":encoding(%s)", $self->term_enc);
  binmode( STDOUT, $layer );
  binmode( STDERR, $layer );
  return Log::Dispatchouli->new({
      ident     => 'Dist::Zilla',
      to_stdout => 1,
      log_pid   => 0,
      to_self   => ($ENV{DZIL_TESTING} ? 1 : 0),
      quiet_fatal => 'stdout',
  });
}

has term_ui => (
  is   => 'ro',
  isa  => 'Object',
  lazy => 1,
  default => sub {
    require Term::ReadLine;
    require Term::UI;
    Term::ReadLine->new('dzil')
  },
);

has term_enc => (
  is   => 'ro',
  isa =>'Str',
  lazy => 1,
  default => sub {
    require Term::Encoding;
    return Term::Encoding::get_encoding();
  },
);

sub prompt_str {
  my ($self, $prompt, $arg) = @_;
  $arg ||= {};
  my $default = $arg->{default};
  my $check   = $arg->{check};

  require Encode;
  my $term_enc = $self->term_enc;

  if ($arg->{noecho}) {
    require Term::ReadKey;
    Term::ReadKey::ReadMode('noecho');
  }
  my $input_bytes = $self->term_ui->get_reply(
    prompt => Encode::encode($term_enc, $prompt, Encode::FB_CROAK()),
    allow  => $check || sub { defined $_[0] and length $_[0] },
    (defined $default
      ? (default => Encode::encode($term_enc, $default, Encode::FB_CROAK()))
      : ()
    ),
  );
  if ($arg->{noecho}) {
    Term::ReadKey::ReadMode('normal');
    # The \n ending user input disappears under noecho; this ensures
    # the next output ends up on the next line.
    print "\n";
  }

  my $input = Encode::decode($term_enc, $input_bytes, Encode::FB_CROAK());
  chomp $input;

  return $input;
}

sub prompt_yn {
  my ($self, $prompt, $arg) = @_;
  $arg ||= {};
  my $default = $arg->{default};

  my $input = $self->term_ui->ask_yn(
    prompt  => $prompt,
    (defined $default ? (default => OneZero->coerce($default)) : ()),
  );

  return $input;
}

sub prompt_any_key {
  my ($self, $prompt) = @_;
  $prompt ||= 'press any key to continue';

  my $isa_tty = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT));

  if ($isa_tty) {
    local $| = 1;
    print $prompt;

    require Term::ReadKey;
    Term::ReadKey::ReadMode('cbreak');
    Term::ReadKey::ReadKey(0);
    Term::ReadKey::ReadMode('normal');
    print "\n";
  }
}

with 'Dist::Zilla::Role::Chrome';

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Dist::Zilla::Chrome::Term - chrome used for terminal-based interaction

=head1 VERSION

version 5.006

=head1 OVERVIEW

This class provides a L<Dist::Zilla::Chrome> implementation for use in a
terminal environment.  It's the default chrome used by L<Dist::Zilla::App>.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut