import React from 'react';
import { withRouter } from 'react-router-dom';
import { withAuth } from '@okta/okta-react';

class SubmissionPage extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      title: '',
      abstract: '',
      submitted: false
    };

    this.handleTitleChange = this.handleTitleChange.bind(this);
    this.handleAbstractChange = this.handleAbstractChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
    this.loadSubmission = this.loadSubmission.bind(this);
  }

  handleTitleChange(e) {
    this.setState({ title: e.target.value });
  }

  handleAbstractChange(e) {
    this.setState({ abstract: e.target.value });
  }

  async loadSubmission() {
    fetch(`/api/sessions/${this.props.match.params.sessionId}`, {
      cache: 'no-cache',
      headers: {
        'content-type':'application/json',
        Authorization: 'Bearer ' + await this.props.auth.getAccessToken()
      }
    })
    .then(rsp => rsp.json())
    .then(session => {
      this.setState(Object.assign({}, this.state, session));
    })
    .catch(err => {
      console.error(err);
    });
  }

  async handleSubmit(e){
    e.preventDefault();
    var sessionId = this.props.match.params.sessionId;
    var url = sessionId ? `/api/sessions/${sessionId}` : '/api/sessions';
    fetch(url, {
      body: JSON.stringify(this.state),
      cache: 'no-cache',
      headers: {
        'content-type':'application/json',
        Authorization: 'Bearer ' + await this.props.auth.getAccessToken()
      },
      method: 'POST'
    })
    .then(rsp => {
      if(rsp.status === 201){
        this.props.history.push('/profile');
      }
    })
    .catch(err => {
      console.error(err);
    });
  }

  componentDidMount(){
    if(this.props.match.params.sessionId){
      this.loadSubmission();
    }
  }

  render(){
    if(this.state.submitted === true){
      <Redirect to="/profile"/>
    }
    return(
        <section>
            <h1>Submissions</h1>
            <form onSubmit={this.handleSubmit}>
                <div className="form-element">
                <label>Title:</label>
                <input
                    id="title" type="text"
                    value={this.state.title}
                    onChange={this.handleTitleChange} />
                </div>
                <div className="form-element">
                <label>Abstract:</label>
                <textarea
                    id="abstract"
                    cols="100"
                    rows="10"
                    value={this.state.abstract}
                    onChange={this.handleAbstractChange} />
                </div>
                <div className="form-actions">
                <input id="submit" type="submit" value="Submit Session"/>
                </div>
            </form>
        </section>
    );
  }

};

export default withAuth(withRouter(SubmissionPage));