package Perinci::Gen::ForModule;

use 5.010;
use strict;
use warnings;

use Exporter::Lite;
use Log::Any '$log';
use SHARYANTO::Array::Util   qw(match_array_or_regex);
use SHARYANTO::Package::Util qw(package_exists list_package_contents);

our @EXPORT_OK = qw(gen_meta_for_module);

our $VERSION = '0.03'; # VERSION

our %SPEC;

$SPEC{gen_meta_for_module} = {
    v => 1.1,
    summary => 'Generate metadata for a module',
    description => <<'_',

This function can be used to automatically generate Rinci metadata for a
"traditional" Perl module which do not have any. Currently, only a plain and
generic package and function metadata are generated.

The resulting metadata will be put in %<PACKAGE>::SPEC. Functions that already
have metadata in the %SPEC will be skipped. The metadata will have
C<result_naked> property set to true, C<args_as> set to C<array>, and C<args>
set to C<{args => ["any" => {schema=>'any', pos=>0, greedy=>1}]}>. In the
future, function's arguments (and other properties) will be parsed from POD (and
other indicators).

_
    args => {
        module => {
            schema => 'str*',
            summary => 'The module name',
        },
        load => {
            schema => ['bool*' => {default=>1}],
            summary => 'Whether to load the module using require()',
        },
        include_subs => {
            schema => ['any' => { # XXX or regex
                of => [['array*'=>{of=>'str*'}], 'str*'], # 2nd should be regex*
            }],
            summary => 'If specified, only include these subs',
        },
        exclude_subs => {
            schema => ['any' => { # XXX or regex
                of => [['array*'=>{of=>'str*'}], 'str*'], # 2nd should be regex*
                default => '^_',
            }],
            summary => 'If specified, exclude these subs',
            description => <<'_',

By default, exclude private subroutines (subroutines which have _ prefix in
their names).

_
        },
    },
};
sub gen_meta_for_module {
    my %args = @_;

    my $inc = $args{include_subs};
    my $exc = $args{exclude_subs} // qr/^_/;

    # XXX schema
    my $module = $args{module}
        or return [400, "Please specify module"];
    my $load = $args{load} // 1;

    if ($load) {
        eval {
            my $modulep = $module; $modulep =~ s!::!/!g;
            require "$modulep.pm";
        };
        my $eval_err = $@;
        #return [500, "Can't load module $module: $eval_err"] if $eval_err;
        # ignore the error and try to load it anyway
    }
    return [500, "Package $module does not exist"]
        unless package_exists($module);

    my $note;
    {
        no strict 'vars'; # for $VERSION
        $note = "This metadata is automatically generated by ".
            __PACKAGE__." version ".($VERSION//"?")." on ".localtime();
    }

    my $metas;
    {
        no strict 'refs';
        $metas = \%{"$module\::SPEC"};
    }

    # generate package metadata
    if ($metas->{":package"}) {
        $log->info("Not creating metadata for package $module: ".
                       "already defined");
    } else {
        $metas->{":package"} = {
            v => 1.1,
            summary => $module,
            description => $note,
        };
    }

    my %content = list_package_contents($module);

    # generate subroutine metadatas

    for my $sub (sort grep {ref($content{$_}) eq 'CODE'} keys %content) {
        $log->tracef("Adding meta for subroutine %s ...", $sub);
        if (defined($inc) && !match_array_or_regex($sub, $inc)) {
            $log->info("Not creating metadata for sub $module\::$sub: ".
                           "doesn't match include_subs");
            next;
        }
        if (defined($exc) &&  match_array_or_regex($sub, $exc)) {
            $log->info("Not creating metadata for sub $module\::$sub: ".
                           "matches exclude_subs");
            next;
        }
        if ($metas->{$sub}) {
            $log->info("Not creating metadata for sub $module\::$sub: ".
                           "already defined");
            next;
        }

        my $meta = {
            v => 1.1,
            summary => $sub,
            description => $note,
            result_naked => 1,
            args_as => 'array',
            args => {
                args => {
                    schema => ['array*' => {of=>'any'}],
                    summary => 'Arguments',
                    pos => 0,
                    greedy => 1,
                },
            },
        };
        $metas->{$sub} = $meta;
    }

    [200, "OK", $metas];
}

1;
#ABSTRACT: Generate metadata for a module


__END__
=pod

=head1 NAME

Perinci::Gen::ForModule - Generate metadata for a module

=head1 VERSION

version 0.03

=head1 SYNOPSIS

In Foo/Bar.pm:

 package Foo::Bar;
 sub sub1 { ... }
 sub sub2 { ... }
 1;

In another script:

 use Perinci::Gen::FromModule qw(gen_meta_for_module);
 gen_meta_for_module(module=>'Foo::Bar');

Now Foo::Bar has metadata stored in %Foo::Bar::SPEC.

=head1 DESCRIPTION

This module provides gen_meta_for_module().

This module uses L<Log::Any> for logging framework.

This module has L<Rinci> metadata.

=head1 FAQ

=head1 SEE ALSO

L<Perinci>, L<Rinci>

=head1 FUNCTIONS


=head2 gen_meta_for_module(%args) -> [status, msg, result, meta]

Generate metadata for a module.

This function can be used to automatically generate Rinci metadata for a
"traditional" Perl module which do not have any. Currently, only a plain and
generic package and function metadata are generated.

The resulting metadata will be put in %::SPEC. Functions that already
have metadata in the %SPEC will be skipped. The metadata will have
C property set to true, C set to C, and C
set to C ["any" => {schema=>'any', pos=>0, greedy=>1}]}>. In the
future, function's arguments (and other properties) will be parsed from POD (and
other indicators).

Arguments ('*' denotes required arguments):

=over 4

=item * B<exclude_subs> => I<array|str> (default: "^_")

If specified, exclude these subs.

By default, exclude private subroutines (subroutines which have _ prefix in
their names).

=item * B<include_subs> => I<array|str>

If specified, only include these subs.

=item * B<load>* => I<bool> (default: 1)

Whether to load the module using require().

=item * B<module>* => I<str>

The module name.

=back

Return value:

Returns an enveloped result (an array). First element (status) is an integer containing HTTP status code (200 means OK, 4xx caller error, 5xx function error). Second element (msg) is a string containing error message, or 'OK' if status is 200. Third element (result) is optional, the actual result. Fourth element (meta) is called result metadata and is optional, a hash that contains extra information.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

