#
# This file is part of Dist-Zilla-Plugin-Git
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Dist::Zilla::Role::Git::DirtyFiles;
{
  $Dist::Zilla::Role::Git::DirtyFiles::VERSION = '2.019';
}
# ABSTRACT: provide the allow_dirty & changelog attributes

use Moose::Role;
use Moose::Autobox;
use MooseX::Types::Moose qw{ ArrayRef Str RegexpRef };
use Moose::Util::TypeConstraints;

use namespace::autoclean;
use List::Util 'first';
use Path::Class;
use Try::Tiny;

requires qw(log_fatal repo_root zilla);

# -- attributes


has allow_dirty => (
  is => 'ro', lazy => 1,
  isa     => ArrayRef[Str],
  builder => '_build_allow_dirty',
);
has changelog => ( is => 'ro', isa=>Str, default => 'Changes' );

{
  my $type = subtype as ArrayRef[RegexpRef];
  coerce $type, from ArrayRef[Str], via { [map { qr/$_/ } @$_] };
  has allow_dirty_match => (
    is => 'ro',
    lazy => 1,
    coerce => 1,
    isa => $type,
    default => sub { [] },
  );
}

around mvp_multivalue_args => sub {
  my ($orig, $self) = @_;

  my @start = $self->$orig;
  return (@start, 'allow_dirty', 'allow_dirty_match');
};

# -- builders & initializers

sub _build_allow_dirty { [ 'dist.ini', shift->changelog ] }




sub list_dirty_files
{
  my ($self, $git, $listAllowed) = @_;

  my $git_root  = $self->repo_root;
  my @filenames = $self->allow_dirty->flatten;

  if ($git_root ne '.') {
    # Interpret allow_dirty relative to the dzil root
    my $dzil_root = $self->zilla->root->absolute->resolve;
    $git_root     = dir($git_root)
                      ->absolute($dzil_root)
                      ->resolve;

    $self->log_fatal("Dzil root $dzil_root is not inside Git root $git_root")
        unless $git_root->subsumes($dzil_root);

    for my $fn (@filenames) {
      try {
        $fn = file($fn)
                ->absolute($dzil_root)
                ->resolve            # process ..
                ->relative($git_root)
                ->as_foreign('Unix') # Git always uses Unix-style paths
                ->stringify;
      };
    }
  } # end if git root ne dzil root

  my $allowed = join '|', $self->allow_dirty_match->flatten, map { qr{^\Q$_\E$} } @filenames;

  return grep { /$allowed/ ? $listAllowed : !$listAllowed }
      $git->ls_files( { modified=>1, deleted=>1 } );
} # end list_dirty_files


1;

__END__

=pod

=head1 NAME

Dist::Zilla::Role::Git::DirtyFiles - provide the allow_dirty & changelog attributes

=head1 VERSION

version 2.019

=head1 DESCRIPTION

This role is used within the git plugin to work with files that are
dirty in the local git checkout.

=head1 ATTRIBUTES

=head2 allow_dirty

A list of files that are allowed to be dirty in the git checkout.
Defaults to C<dist.ini> and the changelog (as defined per the
C<changelog> attribute.

If your C<repo_root> is not the default (C<.>), then these filenames
are relative to Dist::Zilla's root directory, not the Git root directory.

=head2 changelog

The name of the changelog. Defaults to C<Changes>.

=head1 METHODS

=head2 list_dirty_files

  my @dirty = $plugin->list_dirty_files($git, $listAllowed);

This returns a list of the modified or deleted files in C<$git>,
filtered against the C<allow_dirty> attribute.  If C<$listAllowed> is
true, only allowed files are listed.  If it's false, only files that
are not allowed to be dirty are listed.

In scalar context, returns the number of dirty files.

=for Pod::Coverage mvp_multivalue_args

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut