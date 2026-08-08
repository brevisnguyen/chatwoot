import { actions } from '../../agent';
import { agents } from './data';
import { getFromCache, setCache } from 'shared/helpers/cache';
import { getAvailableAgents } from 'widget/api/agent';

let commit = vi.fn();
vi.mock('widget/helpers/axios');

vi.mock('widget/api/agent');
vi.mock('shared/helpers/cache');

describe('#actions', () => {
  describe('#fetchAvailableAgents', () => {
    const websiteToken = 'test-token';

    beforeEach(() => {
      commit = vi.fn();
      vi.clearAllMocks();
    });

    it('uses cached data then always re-fetches fresh agents', async () => {
      const freshAgents = [{ ...agents[0], avatar_url: 'https://fresh.url' }];
      getFromCache.mockReturnValue(agents);
      getAvailableAgents.mockReturnValue({ data: { payload: freshAgents } });

      await actions.fetchAvailableAgents({ commit }, websiteToken);

      expect(getFromCache).toHaveBeenCalledWith(
        `chatwoot_available_agents_${websiteToken}`
      );
      expect(getAvailableAgents).toHaveBeenCalledWith(websiteToken);
      expect(setCache).toHaveBeenCalledWith(
        `chatwoot_available_agents_${websiteToken}`,
        freshAgents
      );
      expect(commit.mock.calls).toEqual([
        ['setAgents', agents],
        ['setError', false],
        ['setHasFetched', true],
        ['setAgents', freshAgents],
        ['setError', false],
        ['setHasFetched', true],
      ]);
    });

    it('fetches and caches data if no cache available', async () => {
      getFromCache.mockReturnValue(null);
      getAvailableAgents.mockReturnValue({ data: { payload: agents } });

      await actions.fetchAvailableAgents({ commit }, websiteToken);

      expect(getFromCache).toHaveBeenCalledWith(
        `chatwoot_available_agents_${websiteToken}`
      );
      expect(getAvailableAgents).toHaveBeenCalledWith(websiteToken);
      expect(setCache).toHaveBeenCalledWith(
        `chatwoot_available_agents_${websiteToken}`,
        agents
      );
      expect(commit).toHaveBeenCalledWith('setAgents', agents);
      expect(commit).toHaveBeenCalledWith('setError', false);
      expect(commit).toHaveBeenCalledWith('setHasFetched', true);
    });

    it('sends correct actions if API is success', async () => {
      getFromCache.mockReturnValue(null);

      getAvailableAgents.mockReturnValue({ data: { payload: agents } });
      await actions.fetchAvailableAgents({ commit }, 'Hi');
      expect(commit.mock.calls).toEqual([
        ['setAgents', agents],
        ['setError', false],
        ['setHasFetched', true],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      getFromCache.mockReturnValue(null);

      getAvailableAgents.mockRejectedValue({
        message: 'Authentication required',
      });
      await actions.fetchAvailableAgents({ commit }, 'Hi');
      expect(commit.mock.calls).toEqual([
        ['setError', true],
        ['setHasFetched', true],
      ]);
    });

    it('keeps cached agents when re-fetch fails', async () => {
      getFromCache.mockReturnValue(agents);
      getAvailableAgents.mockRejectedValue({
        message: 'Authentication required',
      });

      await actions.fetchAvailableAgents({ commit }, websiteToken);

      expect(commit.mock.calls).toEqual([
        ['setAgents', agents],
        ['setError', false],
        ['setHasFetched', true],
        ['setError', true],
        ['setHasFetched', true],
      ]);
    });
  });

  describe('#updatePresence', () => {
    it('commits the correct presence value', () => {
      actions.updatePresence({ commit }, { 1: 'online' });
      expect(commit.mock.calls).toEqual([['updatePresence', { 1: 'online' }]]);
    });
  });
});
