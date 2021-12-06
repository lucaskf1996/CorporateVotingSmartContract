struct Voter:
    weight: uint256 # weight of vote
    voted: uint256 # 0=no vote, 1=first proposal, 2=second proposal, 3=blank
    permission: bool # has the right to vote
    participate: bool # can interact
    delegated: address # delegate vote to other voter

struct Proposal:
    proposal: String[100] # short name for proposal
    count: uint256 # count for times voted

voters_list: HashMap[address, Voter]
proposal_list: HashMap[uint256, Proposal]
admin: address
end_time: uint256
time_limit: uint256
voting_started: bool
anon: bool

@external
def __init__(proposal1: String[100], proposal2: String[100], time_limit: uint256, _anon: bool):
    self.admin = msg.sender
    self.voting_started = False
    self.anon = _anon
    self.time_limit = time_limit
    self.proposal_list[1] = Proposal({
        proposal: proposal1,
        count: 0
    })
    self.proposal_list[2] = Proposal({
        proposal: proposal2,
        count: 0
    })

@external
def start_voting():
    assert self.admin == msg.sender, "So pode ser utilizado pelo criador do contrato"
    self.voting_started = True
    self.end_time = block.timestamp + self.time_limit

@external
def givePermission(voter_address: address, vote_weight: uint256):
    assert self.admin == msg.sender, "So pode ser utilizado pelo criador do contrato"
    assert not self.voters_list[voter_address].permission, "Usuario ja pode votar"
    self.voters_list[voter_address].permission = True
    self.voters_list[voter_address].participate = True
    self.voters_list[voter_address].weight = vote_weight

@external
def giveParticipation(voter_address: address):
    assert self.admin == msg.sender, "So pode ser utilizado pelo criador do contrato"
    assert not self.voters_list[voter_address].participate, "Ja pode participar"
    self.voters_list[voter_address].participate = True

@external
def vote(proposal_number: uint256):
    assert self.voters_list[msg.sender].permission, "Usuario nao pode votar"
    assert self.voters_list[msg.sender].voted == 0, "Usuario ja votou"
    assert self.voters_list[msg.sender].delegated == ZERO_ADDRESS, "Usuário ja delegou o voto"
    assert self.voting_started, "Votacao nao foi iniciada"
    assert block.timestamp < self.end_time, "Ja passou do tempo"
    assert proposal_number < 4, "Voto invalido. 1(proposta 1), 2(proposta 2), 3(branco)"
    assert proposal_number > 0, "Voto invalido. 1(proposta 1), 2(proposta 2), 3(branco)"
    if proposal_number != 3:
        self.proposal_list[proposal_number].count += self.voters_list[msg.sender].weight
    self.voters_list[msg.sender].voted = proposal_number

@external
def delegate_to(voter_address: address):
    assert self.voters_list[msg.sender].permission, "Usuario nao pode votar"
    assert self.voters_list[msg.sender].voted == 0, "Usuario ja votou"
    assert self.voters_list[msg.sender].delegated == ZERO_ADDRESS, "Usuário ja delegou o voto"
    if self.voting_started:
        assert block.timestamp < self.end_time, "Ja passou do tempo"
    if self.voters_list[voter_address].voted == 1:
        self.proposal_list[1].count += self.voters_list[msg.sender].weight
    elif self.voters_list[voter_address].voted == 2:
        self.proposal_list[2].count += self.voters_list[msg.sender].weight
    self.voters_list[voter_address].weight += self.voters_list[msg.sender].weight
    self.voters_list[msg.sender].delegated = voter_address
    self.voters_list[msg.sender].weight = 0

@view
@external
def winnig_proposal() -> String[100]: # verifica qual proposta passou
    assert self.voters_list[msg.sender].participate, "Usuario nao pode participar"
    assert self.voting_started, "Votacao nao foi iniciada"
    assert block.timestamp >= self.end_time, "o tempo nao acabou"
    if self.proposal_list[1].count > self.proposal_list[2].count:
        return self.proposal_list[1].proposal
    elif self.proposal_list[1].count < self.proposal_list[2].count:
        return self.proposal_list[1].proposal
    else:
        return "Empate"

@view
@external
def vote_has_ended() -> bool: # verifica se terminou o tempo
    assert self.voting_started, "Votacao nao foi iniciada"
    assert self.voters_list[msg.sender].participate, "Usuario nao pode participar"
    return block.timestamp >= self.end_time

@view
@external
def time_remaining() -> uint256: # verifica tempo faltante
    assert self.voting_started, "Votacao nao foi iniciada"
    assert self.voters_list[msg.sender].participate, "Usuario nao pode participar"
    return self.end_time-block.timestamp

@view
@external
def check_vote(voter: address) -> uint256: # verifica quem votou no que
    assert self.voting_started, "Votacao nao foi iniciada"
    assert self.voters_list[msg.sender].participate, "Usuario nao pode participar"
    assert self.anon, "Votacao anonima"
    return self.voters_list[voter].voted

@view
@external
def check_proposition(proposal_num: uint256) -> String[100]: # verifica proposta
    assert self.voters_list[msg.sender].participate, "Usuario nao pode participar"
    return self.proposal_list[proposal_num].proposal
