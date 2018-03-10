import { getOwner } from 'discourse-common/lib/get-owner';

export default {
  setupComponent(attrs, component) {
    const settingEnabled = Discourse.SiteSettings.elections_status_banner_discovery;
    const controller = getOwner(this).lookup('controller:discovery');

    const setPath = () => {
      let currentPath = controller.get('application.currentPath');
      component.set('electionListEnabled', settingEnabled && currentPath.indexOf('calendar') === -1);
    };

    setPath(controller);
    controller.addObserver('application.currentPath', () => {
      if (this._state === 'destroying') return;
      setPath(controller);
    });
  }
};
