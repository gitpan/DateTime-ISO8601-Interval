use strict;
use warnings;

package Path::IsDev::Heuristic::Tool::Dzil;
BEGIN {
  $Path::IsDev::Heuristic::Tool::Dzil::AUTHORITY = 'cpan:KENTNL';
}
{
  $Path::IsDev::Heuristic::Tool::Dzil::VERSION = '1.000002';
}


# ABSTRACT: Determine if a path is a Dist::Zilla Source tree

use Role::Tiny::With qw( with );
with 'Path::IsDev::Role::Heuristic', 'Path::IsDev::Role::Matcher::Child::Exists::Any::File';


sub files { return qw( dist.ini ) }


sub matches {
  my ( $self, $result_object ) = @_;
  if ( $self->child_exists_any_file( $result_object, $self->files ) ) {
    $result_object->result(1);
    return 1;
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::IsDev::Heuristic::Tool::Dzil - Determine if a path is a Dist::Zilla Source tree

=head1 VERSION

version 1.000002

=head1 METHODS

=head2 C<files>

Files relevant to this heuristic:

    dist.ini

=head2 C<matches>

Matches if any of the files in C<files> exist as children of the C<path>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Path::IsDev::Heuristic::Tool::Dzil",
    "interface":"single_class",
    "does":[
        "Path::IsDev::Role::Heuristic",
        "Path::IsDev::Role::Matcher::Child::Exists::Any::File"
    ]
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut