import { Head, router } from '@inertiajs/react'
import { useState } from 'react';
import React from 'react'
import "./RangeComponent.css";

export default function RangeComponent({ orgs, submit_url, csrf_token, repos_url, github_rate}) {
  let [currentOrg, changeOrg] = useState("");
  let [repoList, setRepoList] = useState([]);
  let [currentRate, setRate] = useState(github_rate);

  const onOrgChanged = (e) => {
    let org = e.target.value;
    changeOrg(org);
    if (org == "" || !org) {
      return;
    }
    fetch(repos_url + "?organization=" + org).then(
      (response) => response.json()
    ).then(
      (data) => {
        setRepoList(data.repos);
        setRate(data.github_rate);
      }
    )
  };

  let organization_options =
    ([<option value="" key="">Select an Organization</option>]).concat(orgs.map((o) => {
      return <option value={o} key={o}>{o}</option>
    }));

  let repo_options = ([<option value="" key="nada">Select a Repository</option>]).concat(
    repoList.map((r) => <option value={r} key={r}>{r}</option>)
  );

  return <>
    <Head title="Range" />

    <form action={submit_url} method="post" className="range-component-form">
      <input type="hidden" name="authenticity_token" value={csrf_token} />
      <select name="organization" value={currentOrg} onChange={onOrgChanged} aria-label="Select an Organization">{organization_options}</select>
      <select name="repo" aria-label="Select a Repository">{repo_options}</select>
      <input name="start_sha" defaultValue="" placeholder="Start SHA" aria-label="Start SHA"></input>
      <input name="end_sha" defaultValue="" placeholder="End SHA" aria-label="End SHA"></input>
      <input type="submit" value="Submit"/>
    </form>

    <div>
      <span>Your token has {currentRate.remaining} of {currentRate.limit} requests, and will renew {currentRate.resets_at}.</span>
    </div>
  </>;
}