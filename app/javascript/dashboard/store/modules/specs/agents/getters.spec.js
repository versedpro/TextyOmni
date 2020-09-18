import { getters } from '../../agents';

describe('#getters', () => {
  it('getAgents', () => {
    const state = {
      records: [
        {
          id: 1,
          name: 'Agent 1',
          email: 'agent1@textyomni.com',
          confirmed: true,
        },
        {
          id: 2,
          name: 'Agent 2',
          email: 'agent2@textyomni.com',
          confirmed: false,
        },
      ],
    };
    expect(getters.getAgents(state)).toEqual([
      {
        id: 1,
        name: 'Agent 1',
        email: 'agent1@textyomni.com',
        confirmed: true,
      },
      {
        id: 2,
        name: 'Agent 2',
        email: 'agent2@textyomni.com',
        confirmed: false,
      },
    ]);
  });

  it('getVerifiedAgents', () => {
    const state = {
      records: [
        {
          id: 1,
          name: 'Agent 1',
          email: 'agent1@textyomni.com',
          confirmed: true,
        },
        {
          id: 2,
          name: 'Agent 2',
          email: 'agent2@textyomni.com',
          confirmed: false,
        },
      ],
    };
    expect(getters.getVerifiedAgents(state)).toEqual([
      {
        id: 1,
        name: 'Agent 1',
        email: 'agent1@textyomni.com',
        confirmed: true,
      },
    ]);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
        isCreating: false,
        isUpdating: false,
        isDeleting: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
      isCreating: false,
      isUpdating: false,
      isDeleting: false,
    });
  });
});
