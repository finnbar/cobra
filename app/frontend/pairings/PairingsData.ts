export type PairingsData = {
    tournament_id: number;
    policy: TournamentPolicies;
    stages: Stage[];
}

export type TournamentPolicies = {
    update: boolean;
}

export type Stage = {
    name: string;
    rounds: Round[];
}

export type Round = {
    id: number;
    number: number;
    pairings: Pairing[];
    pairings_reported: number;
}

export type Pairing = {
    id: number;
    round_id: number;
    table_number: number;
    policy: PairingPolicies;
    player1: Player;
    player2: Player;
}

export type PairingPolicies = {
    view_decks: boolean;
}

export type Player = {
    name_with_pronouns: string;
    side_label: string | null;
}
