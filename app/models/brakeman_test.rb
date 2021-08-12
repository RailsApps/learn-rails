# frozen_string_literal: true
#This is a test for SSAAS
module Signals
  module Classifiers
    class CanaryResult < ApplicationModel
      include Signals::Modules::CanaryResultActions

      class << self
        def ignored_csv_headers
          ['id', 'updated_at', 'created_at', 'lock_version'].freeze
        end

        def custom_csv_headers
          ['timestamp', 'result_type', 'network_id', 'network_name', 'signal_name', 'primary_classifier_type',
           'canary_classifier_type', 'recording_url', 'transcript_url'].freeze
        end
      end

      self.table_name = "signal_ai_canary_results"

      declare_schema do
        string   :cuid,                    null: false, limit: 64
        boolean  :primary_prediction,      null: false
        boolean  :canary_prediction,       null: false
        float    :primary_confidence,      null: false
        float    :canary_confidence,       null: false
        string   :canary_transcript_type,  null: true, limit: 64
      end

      belongs_to :primary_remote_classifier, class_name: 'Signals::Classifiers::RemoteClassifier', null: false, optional: true
      belongs_to :canary_remote_classifier,  class_name: 'Signals::Classifiers::RemoteClassifier', null: true, optional: true

      # Require 'canary_transcript_type' or 'canary_remote_classifier' to be present (or both)
      validates :canary_transcript_type,   presence: true, if: -> { canary_remote_classifier.blank? }
      validates :canary_remote_classifier, presence: true, if: -> { canary_transcript_type.blank? }

      index [:primary_remote_classifier_id, :canary_remote_classifier_id, :canary_transcript_type, :cuid],
            name: "signal_ai_canary_result_uniqueness", unique: true

      scope :with_opposite_predictions, -> { where('primary_prediction != canary_prediction') }

      scope :with_opposite_applied_predictions, ->(threshold = Signals::Classifiers::ClassifierRevision::DEFAULT_CONFIDENCE_THRESHOLD) do
        where(<<~SQL)
          (
            /* Primary applied, canary not applied */
            primary_confidence >= #{threshold} AND canary_confidence < #{threshold}
          ) OR (
            /* Canary applied, primary not applied */
            canary_confidence >= #{threshold} AND primary_confidence < #{threshold}
          ) OR (
            /* Primary and canary both applied, but with opposite predictions */
            canary_confidence >= #{threshold} AND primary_confidence >= #{threshold} AND
            primary_prediction != canary_prediction
          )
        SQL
      end

      def result_type
        case [transcript_result?, classifier_result?]
        when [true, true]
          :classifier_and_transcript
        when [true, false]
          :transcript
        when [false, true]
          :classifier
        end
      end

      def transcript_result?
        canary_transcript_type.present?
      end

      def classifier_result?
        canary_remote_classifier.present?
      end

      def signal
        @signal ||=
          case (machine_signal = primary_current_machine_signal)
          when Signals::PreTrainedMachineSignal
            machine_signal.pre_trained_signal
          when Signals::CustomerMachineSignals::Base
            machine_signal.signal
          end
      end

      def signal_name
        signal&.name
      end

      def primary_classifier_type
        if (detail = primary_remote_classifier.classifier_detail)
          [detail.name, detail.version].join('_')
        end
      end

      def canary_classifier_type
        if (detail = canary_remote_classifier&.classifier_detail)
          [detail.name, detail.version].join('_')
        end
      end

      def primary_current_machine_signal
        primary_remote_classifier.classifier_revisions.last&.current_machine_signal
      end
    end
  end
end
