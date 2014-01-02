package Dist::Zilla::Plugin::MetaJSON;
{
  $Dist::Zilla::Plugin::MetaJSON::VERSION = '5.006';
}
# ABSTRACT: produce a META.json
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

use namespace::autoclean;

use Dist::Zilla::File::FromCode;


has filename => (
  is  => 'ro',
  isa => 'Str',
  default => 'META.json',
);


has version => (
  is  => 'ro',
  isa => 'Num',
  default => '2',
);

sub gather_files {
  my ($self, $arg) = @_;

  my $zilla = $self->zilla;

  require JSON;
  JSON->VERSION(2);
  require CPAN::Meta::Converter;
  CPAN::Meta::Converter->VERSION(2.101550); # improved downconversion
  require CPAN::Meta::Validator;
  CPAN::Meta::Validator->VERSION(2.101550); # improved downconversion

  my $file  = Dist::Zilla::File::FromCode->new({
    name => $self->filename,
    # RJBS and XDG didn't 100% agree on this, it's probably fine until somebody
    # comes up with a really good argument to change it (or to remove this
    # comment, settling the argument). -- rjbs, 2013-10-19
    code_return_type => 'bytes',
    code => sub {
      my $distmeta  = $zilla->distmeta;

      my $validator = CPAN::Meta::Validator->new($distmeta);

      unless ($validator->is_valid) {
        my $msg = "Invalid META structure.  Errors found:\n";
        $msg .= join( "\n", $validator->errors );
        $self->log_fatal($msg);
      }

      my $converter = CPAN::Meta::Converter->new($distmeta);
      my $output    = $converter->convert(version => $self->version);

      JSON->new->ascii(1)->canonical(1)->pretty->encode($output)
      . "\n";
    },
  });

  $self->add_file($file);
  return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::MetaJSON - produce a META.json

=head1 VERSION

version 5.006

=head1 DESCRIPTION

This plugin will add a F<META.json> file to the distribution.

This file is meant to replace the old-style F<META.yml>.  For more information
on this file, see L<Module::Build::API> and L<CPAN::Meta>.

=head1 ATTRIBUTES

=head2 filename

If given, parameter allows you to specify an alternate name for the generated
file.  It defaults, of course, to F<META.json>.

=head2 version

This parameter lets you pick what version of the spec to use when generating
the output.  It defaults to 2 at present, but may be updated to new specs as
they are released and adopted.

If you want a fixed version, specify it.

=head1 SEE ALSO

Core Dist::Zilla plugins:
L<@Basic|Dist::Zilla::PluginBundle::Basic>,
L<Manifest|Dist::Zilla::Plugin::Manifest>.

Dist::Zilla roles:
L<FileGatherer|Dist::Zilla::Role::FileGatherer>.

Other modules:
L<CPAN::Meta>,
L<CPAN::Meta::Spec>, L<JSON>.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut