# t.string :name
# t.timestamps
class DocFile < ActiveRecord::Base
  has_many :doc_versions
  has_many :versions, through: :doc_versions

  scope :with_includes, ->{ includes(:doc_versions => [:doc, :version]) }

  def version_changes()
    unchanged_versions = []
    changes = []
    doc_versions = self.doc_versions.includes(:version).version_changes.to_a
    doc_versions.each_with_index do |doc_version, i|
      next unless previous_doc_version = doc_versions[i+1]
      sha2 = doc_version.doc.blob_sha
      sha1 = previous_doc_version.doc.blob_sha
      if sha1 == sha2
        unchanged_versions << doc_version.name
      else
        if unchanged_versions.size > 0
          if unchanged_versions.size == 1
            changes << {name: "#{unchanged_versions.first} no changes", changed: false}
          else
            changes << {name: "#{unchanged_versions.last} &rarr; #{unchanged_versions.first} no changes", changed: false}
          end
          unchanged_versions = []
        end
        changes << {name: doc_version.name, time: doc_version.committed, diff: doc_version.diff(previous_doc_version), changed: true}
      end
    end
    changes
  end

  # TODO: parse file for description
  def description
    ''
  end
end
