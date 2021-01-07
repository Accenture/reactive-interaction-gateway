/**
 * Copyright (c) 2017-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

const React = require("react");

class Footer extends React.Component {
  docUrl(doc, language) {
    const baseUrl = this.props.config.baseUrl;
    return baseUrl + "docs/" + (language ? language + "/" : "") + doc;
  }

  pageUrl(doc, language) {
    const baseUrl = this.props.config.baseUrl;
    return baseUrl + (language ? language + "/" : "") + doc;
  }

  render() {
    const currentYear = new Date().getFullYear();
    return (
      <footer className="nav-footer" id="footer">
        <section className="sitemap">
          <a href={this.props.config.baseUrl} className="nav-home">
            {this.props.config.footerIcon && (
              <img
                src={this.props.config.baseUrl + this.props.config.footerIcon}
                alt={this.props.config.title}
                width="66"
                height="58"
              />
            )}
          </a>
          <div>
            <h5>Docs</h5>
            <a href={this.docUrl("intro.html", this.props.language || "")}>
              Intro
            </a>
            <a
              href={this.docUrl(
                "getting-started.html",
                this.props.language || ""
              )}
            >
              Getting Started
            </a>
          </div>
          <div>
            <h5>Community</h5>
            <a href={this.pageUrl("users.html", this.props.language)}>
              User Showcase
            </a>
            <a
              href="https://rig-slackin.herokuapp.com"
              target="_blank"
              rel="noreferrer noopener"
            >
              Slack
            </a>
            <a
              href="http://stackoverflow.com/questions/tagged/reactive-interaction-gateway"
              target="_blank"
              rel="noreferrer noopener"
            >
              Stack Overflow
            </a>
            {/* <a href="https://discordapp.com/">Project Chat</a> */}
            <a
              href="https://twitter.com/kevnbadr"
              target="_blank"
              rel="noreferrer noopener"
            >
              @KevnBadr
            </a>
          </div>
          <div>
            <h5>More</h5>
            {/* <a href={this.props.config.baseUrl + 'blog'}>Blog</a> */}
            <a
              className="github-button"
              href={this.props.config.repoUrl}
              data-icon="octicon-star"
              data-count-href="/accenture/reactive-interaction-gateway/stargazers"
              data-show-count={true}
              data-count-aria-label="# stargazers on GitHub"
              aria-label="Star RIG on GitHub"
            >
              Star RIG on GitHub
            </a>
          </div>
        </section>

        <section className="copyright">{this.props.config.copyright}</section>
      </footer>
    );
  }
}

module.exports = Footer;
