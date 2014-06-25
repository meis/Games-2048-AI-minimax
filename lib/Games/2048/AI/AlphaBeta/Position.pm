package Games::2048::AI::AlphaBeta::Position;
use v5.12;
use base qw(Games::AlphaBeta::Position);

use Data::Dumper;
my @vecs = ([-1, 0], [1, 0], [0, -1], [0, 1]);

sub init {
    my ( $self, $game ) = @_;
    $self->player(1);
    $self->game($game);
    return $self;
}

sub switch_player {
    my $self = shift;
    if ( $self->{player} == 1 ) {
        $self->player(0);
    }
    else {
        $self->player(1);
    }
}

sub game {
    my $self = shift;
    $self->{game} = shift if @_;
    return $self->{game};
}

# Methods required by Games::AlphaBeta
sub apply {
    my ( $self, $move ) = @_;

    my $game = dclone $self->game;
    if ( $self->player) {
        $game->move_tiles([$move->[0], $move->[1]]);
    }
    else {
        $game->insert_tile([$move->[0], $move->[1]],$move->[2]);
    }
    $self->game($game);

#say Dumper($move);
    $self->switch_player;

    $self;
}
sub endpos { }          # optional

sub findmoves {
    my $self = shift;

    #return unless my $game = dclone $self->game;
    my @moves;

    if ( $self->player ) {
        for (0..3) {
            my $g = dclone $self->game;

            my $move = $vecs[$_];
            if ($g->move_tiles($move)) {
                push @moves, $move;
            }
        }
    }
    else {
        @moves = map { ([$_->[0], $_->[1], 2], [$_->[0], $_->[1], 4]) } $self->game->available_cells;
    }
    @moves;
}

sub evaluate {
    my $self = shift;

    my $board = $self->game->_tiles;

    my $max_value       = 1 * $self->_max_value;
    my $max_in_corner   = 500 * $self->_max_in_corner($self->_max_value);
    my $grows           = 0.5 * $self->_grows;
    my $game_score      = 1 * $self->_game_score;
    my $tiles_score     = 1  * $self->_tiles_score;
    my $available_cells = 2 * ( -16 + $self->game->available_cells ) ;

    my $score = 0                +
                $max_value       +
                $game_score      +
                $max_in_corner   +
                $available_cells +
                $tiles_score     +
                $grows           ;

    $score++ if $self->game->_tiles->[0][0];
    return $self->player? $score: -$score;
}

sub _game_score { shift->game->score }

sub _grows {
    my $self = shift;
    my $t = $self->game->_tiles;

    my $score = 0;
    $score += $self->_list_grows( $t->[0][0], $t->[0][1], $t->[0][2], $t->[0][3] ) * 2;
    $score += $self->_list_grows( $t->[1][0], $t->[1][1], $t->[1][2], $t->[1][3] );
    $score += $self->_list_grows( $t->[2][0], $t->[2][1], $t->[2][2], $t->[2][3] );
    $score += $self->_list_grows( $t->[3][0], $t->[3][1], $t->[3][2], $t->[3][3] ) * 2;

    $score += $self->_list_grows( $t->[0][0], $t->[1][0], $t->[2][0], $t->[3][0] ) * 2;
    $score += $self->_list_grows( $t->[0][1], $t->[1][1], $t->[2][1], $t->[3][1] );
    $score += $self->_list_grows( $t->[0][2], $t->[1][2], $t->[2][2], $t->[3][2] );
    $score += $self->_list_grows( $t->[0][3], $t->[1][3], $t->[2][3], $t->[3][3] ) * 2;

    $score;
}

sub _list_grows {
    my $self = shift;
    my @list = @_;
    return 0 unless my @values = map { $_->value }
                                 grep {$_} @list;

    # List of 1 does not grow
    return 0 if @list == 1;
    my $sorted = $self->_values_sorted(@values) || $self->_values_sorted(reverse @values);
    return $sorted * @list;
}

sub _values_sorted {
    my $self = shift;
    my @values = @_;

    my $idx = 0;
    my $last_val = $values[$idx];
    my $sorted = $last_val;

    while ( my $new_val = $values[$idx++] ) {
        if ( $new_val < $last_val ) {
            $sorted = 0;
        }
        else {
            $sorted += $new_val * $new_val;
        }
        $last_val = $new_val;
    }

    $sorted;
}

sub _max_value {
    my $self = shift;

    my $board = $self->game->_tiles;

    my $max = 0;
    for my $y ( @$board ) {
        for my $x ( @$y ) {
            if ( $x ) {
                $max = $x->value if $x->value > $max;
            }
        }
    }
    return $max;
}

sub _tiles_score {
    my $self = shift;

    my $board = $self->game->_tiles;

    my $score= 0;
    for my $y ( @$board ) {
        for my $x ( @$y ) {
            if ( $x ) {
                $score += $x->value * $x->value;;
            }
        }
    }
    return $score;
}

sub _max_in_corner {
    my ( $self, $max ) = @_;

    my $board = $self->game->_tiles;

    return $max if $board->[0][0] && $board->[0][0]->value == $max;
    return $max if $board->[0][3] && $board->[0][3]->value == $max;
    return $max if $board->[3][0] && $board->[3][0]->value == $max;
    return $max if $board->[3][3] && $board->[3][3]->value == $max;

    return 0;
}

sub to_string {
    my $self = shift;
    my $t = $self->game->_tiles;

    say "|" . $self->print_cell($t->[0][0]) . "|" . $self->print_cell($t->[0][1]) . "|" . $self->print_cell($t->[0][2]) . "|". $self->print_cell($t->[0][3]) . "|";
    say "|" . $self->print_cell($t->[1][0]) . "|" . $self->print_cell($t->[1][1]) . "|" . $self->print_cell($t->[1][2]) . "|". $self->print_cell($t->[1][3]) . "|";
    say "|" . $self->print_cell($t->[2][0]) . "|" . $self->print_cell($t->[2][1]) . "|" . $self->print_cell($t->[2][2]) . "|". $self->print_cell($t->[2][3]) . "|";
    say "|" . $self->print_cell($t->[3][0]) . "|" . $self->print_cell($t->[3][1]) . "|" . $self->print_cell($t->[3][2]) . "|". $self->print_cell($t->[3][3]) . "|";
}

sub print_cell {
    my ( $self, $cell ) = @_;
    sprintf("%04d", $cell ? $cell->value : 0);
}

1;
