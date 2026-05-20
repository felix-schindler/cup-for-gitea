import SwiftUI

struct ActivityView: View {
    let activity: Components.Schemas.Activity
    var showActor: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if showActor {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        SmallUserView(activity.actUser, avatarSize: .small)
                    }
                }
            }

            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.callout)
                    .frame(width: 16)

                (Text(actorName).fontWeight(.medium) + description)
                    .font(.callout)
                    .lineLimit(2)
            }

            NavigationLink(destination: destinationView) {
                Text(activity.repo.fullName)
                    .font(.caption)
                    .foregroundStyle(.accent)
            }
            .buttonStyle(.plain)

            if activity.content.isNotEmpty {
                Text(activity.content.emojized())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Text(activity.created.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var actorName: String {
        let actor = activity.actUser
        if actor.fullName.isNotEmpty {
            return actor.fullName
        }
        return actor.login
    }

    @ViewBuilder
    private var destinationView: some View {
        let owner = activity.repo.owner.login
        let repo = activity.repo.name
        let ref = activity.refName

        switch activity.opType {
        case .createIssue, .commentIssue, .closeIssue, .reopenIssue:
            if let index = Int64(ref) {
                IssueLoader(owner: owner, repo: repo, index: index)
            } else {
                FullRepoView(activity.repo)
            }
        case .createPullRequest, .mergePullRequest, .closePullRequest, .reopenPullRequest,
                .commentPull, .approvePullRequest, .rejectPullRequest, .pullReviewDismissed,
                .pullRequestReadyForReview, .autoMergePullRequest:
            if let index = Int64(ref) {
                PullRequestLoader(owner: owner, repo: repo, index: index)
            } else {
                FullRepoView(activity.repo)
            }
        case .commitRepo:
            CommitsLoader(owner: owner, repo: repo, ref: ref)
        case .pushTag, .deleteTag:
            TagsLoader(owner: owner, repo: repo)
        case .publishRelease:
            ReleaseLoader(owner: owner, repo: repo)
        case .deleteBranch:
            BranchesLoader(owner: owner, repo: repo)
        default:
            FullRepoView(activity.repo)
        }
    }

    private var icon: String {
        switch activity.opType {
        case .createRepo:             return "book.closed"
        case .renameRepo:             return "pencil"
        case .starRepo:               return "star"
        case .watchRepo:              return "eye"
        case .commitRepo:             return "checkmark.circle"
        case .createIssue:            return "dot.circle"
        case .createPullRequest:     return "arrow.triangle.pull"
        case .transferRepo:           return "arrow.left.arrow.right"
        case .pushTag:                return "tag"
        case .commentIssue:           return "note.text"
        case .mergePullRequest:      return "arrow.triangle.merge"
        case .closeIssue:             return "xmark.circle"
        case .reopenIssue:            return "arrow.circlepath"
        case .closePullRequest:      return "xmark.circle"
        case .reopenPullRequest:     return "arrow.circlepath"
        case .deleteTag:              return "tag.slash"
        case .deleteBranch:           return "arrow.triangle.branch.slash"
        case .mirrorSyncPush:         return "arrow.triangle.2.circlepath"
        case .mirrorSyncCreate:       return "arrow.triangle.2.circlepath"
        case .mirrorSyncDelete:       return "arrow.triangle.2.circlepath"
        case .approvePullRequest:    return "checkmark.seal"
        case .rejectPullRequest:     return "xmark.seal"
        case .commentPull:            return "note.text"
        case .publishRelease:         return "music.note"
        case .pullReviewDismissed:   return "xmark.seal"
        case .pullRequestReadyForReview: return "arrow.triangle.pull"
        case .autoMergePullRequest:  return "arrow.triangle.merge"
        default:                        return "ellipsis"
        }
    }

    private var iconColor: Color {
        switch activity.opType {
        case .starRepo, .watchRepo:               return .yellow
        case .createRepo, .pushTag, .publishRelease: return .green
        case .createIssue, .reopenIssue, .reopenPullRequest: return .green
        case .closeIssue, .closePullRequest, .deleteTag, .deleteBranch: return .red
        case .mergePullRequest, .autoMergePullRequest: return .purple
        case .approvePullRequest:                 return .green
        case .rejectPullRequest, .pullReviewDismissed: return .red
        case .commentIssue, .commentPull:         return .blue
        case .commitRepo:                           return .teal
        default:                                      return .secondary
        }
    }

    private var description: Text {
        let ref = activity.refName

        switch activity.opType {
        case .createRepo:
            return Text(" created repository")

        case .renameRepo:
            return Text(" renamed repository")

        case .starRepo:
            return Text(" starred ")

        case .watchRepo:
            return Text(" started watching ")

        case .commitRepo:
            if ref.isNotEmpty {
                return Text(" pushed to \(ref)")
            }
            return Text(" pushed to ")

        case .createIssue:
            if ref.isNotEmpty {
                return Text(" opened issue \(ref) in ")
            }
            return Text(" opened issue in ")

        case .createPullRequest:
            if ref.isNotEmpty {
                return Text(" opened pull request \(ref) in ")
            }
            return Text(" opened pull request in ")

        case .transferRepo:
            return Text(" transferred repository")

        case .pushTag:
            if ref.isNotEmpty {
                return Text(" pushed tag \(ref) to ")
            }
            return Text(" pushed tag to ")

        case .commentIssue:
            if ref.isNotEmpty {
                return Text(" commented on issue \(ref) in ")
            }
            return Text(" commented on issue in ")

        case .mergePullRequest:
            if ref.isNotEmpty {
                return Text(" merged pull request \(ref) in ")
            }
            return Text(" merged pull request in ")

        case .closeIssue:
            if ref.isNotEmpty {
                return Text(" closed issue \(ref) in ")
            }
            return Text(" closed issue in ")

        case .reopenIssue:
            if ref.isNotEmpty {
                return Text(" reopened issue \(ref) in ")
            }
            return Text(" reopened issue in ")

        case .closePullRequest:
            if ref.isNotEmpty {
                return Text(" closed pull request \(ref) in ")
            }
            return Text(" closed pull request in ")

        case .reopenPullRequest:
            if ref.isNotEmpty {
                return Text(" reopened pull request \(ref) in ")
            }
            return Text(" reopened pull request in ")

        case .deleteTag:
            if ref.isNotEmpty {
                return Text(" deleted tag \(ref) from ")
            }
            return Text(" deleted tag from ")

        case .deleteBranch:
            if ref.isNotEmpty {
                return Text(" deleted branch \(ref) from ")
            }
            return Text(" deleted branch from ")

        case .mirrorSyncPush:
            return Text(" mirror-pushed to ")

        case .mirrorSyncCreate:
            return Text(" mirror-created in ")

        case .mirrorSyncDelete:
            return Text(" mirror-deleted from ")

        case .approvePullRequest:
            if ref.isNotEmpty {
                return Text(" approved pull request \(ref) in ")
            }
            return Text(" approved pull request in ")

        case .rejectPullRequest:
            if ref.isNotEmpty {
                return Text(" rejected pull request \(ref) in ")
            }
            return Text(" rejected pull request in ")

        case .commentPull:
            if ref.isNotEmpty {
                return Text(" commented on pull request \(ref) in ")
            }
            return Text(" commented on pull request in ")

        case .publishRelease:
            if ref.isNotEmpty {
                return Text(" published release \(ref) in ")
            }
            return Text(" published release in ")

        case .pullReviewDismissed:
            if ref.isNotEmpty {
                return Text(" dismissed review on pull request \(ref) in ")
            }
            return Text(" dismissed review on pull request in ")

        case .pullRequestReadyForReview:
            if ref.isNotEmpty {
                return Text(" marked pull request \(ref) ready for review in ")
            }
            return Text(" marked pull request ready for review in ")

        case .autoMergePullRequest:
            if ref.isNotEmpty {
                return Text(" auto-merged pull request \(ref) in ")
            }
            return Text(" auto-merged pull request in ")

        default:
            return Text(" acted")
        }
    }
}
