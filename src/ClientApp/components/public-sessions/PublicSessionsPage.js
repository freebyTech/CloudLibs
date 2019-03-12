import React from 'react';
import { withAuth } from '@okta/okta-react';

import Session from '../sessions/Session';

export default class PublicSessionsPage extends React.Component {
  constructor(props) {
    super(props);
    this.state = { sessions: [] }
  }

  async getAllSessions() {
    fetch('/api/publicsessions', {
      cache: 'no-cache',
      headers: {
        'content-type':'application/json',
      }
    })
    .then(rsp => rsp.json())
    .then(sessions => {
      this.setState({ sessions });
    })
    .catch(err => {
      console.error(err);
    });
  }

  componentDidMount() {
    this.getAllSessions();
  }

  render() {
    
      return(
        <section> 
          { (this.state.sessions.length === 0)
            ? <h1>No sessions have been released yet, please check back later.</h1> 
            :  <ul className="session-list">
            { this.state.sessions.map(session =>
            <Session key={session.sessionId}
              id={session.sessionId}
              isOwner={false}
              session={session} />) }
          </ul> }
        </section>
      )
  }
}