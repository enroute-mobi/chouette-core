# coding: utf-8
require 'htmlbeautifier'

module TableBuilderHelper
  include Pundit
end

describe TableBuilderHelper, type: :helper do
  let(:features){ [] }
  before do
    allow_any_instance_of(AF83::Decorator::Link).to receive(:check_feature){|f|
      features.include?(f)
    }
  end

  describe "#table_builder_2" do
    it "builds a table" do
      referential = create(:workbench_referential)
      workbench = referential.workbench
      referential.organisation.workbenches << workbench

      user_context = UserContext.new(
        build_stubbed(
          :user,
          organisation: referential.organisation,
          permissions: [
            'referentials.create',
            'referentials.update',
            'referentials.destroy',
          ]
        ),
        referential: referential
      )
      allow(helper).to receive(:pundit_user).and_return(user_context)
      allow(helper).to receive(:current_user).and_return(user_context.user)

      referentials = [referential]

      allow(referentials).to receive(:model).and_return(Referential)
      stub_policy_scope(referential)

      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(
        controller: 'workbenches',
        action: 'show',
        id: referentials[0].workbench.id
      ))

      referentials = ReferentialDecorator.decorate(
        referentials
      )

      expected = <<-HTML
<table class="table has-filter has-search">
    <thead>
        <tr>
            <th>
                <div class="checkbox"><input type="checkbox" name="0" id="0" value="all" /><label for="0"></label></div>
            </th>
            <th><a href="/workbenches/#{workbench.id}?direction=desc&amp;sort=name">Nom<span class="orderers"><span class="fa fa-sort-up "></span><span class="fa fa-sort-down "></span></span></a></th>
            <th><a href="/workbenches/#{workbench.id}?direction=desc&amp;sort=status">État<span class="orderers"><span class="fa fa-sort-up "></span><span class="fa fa-sort-down "></span></span></a></th>
            <th><a href="/workbenches/#{workbench.id}?direction=desc&amp;sort=organisation">Organisation<span class="orderers"><span class="fa fa-sort-up "></span><span class="fa fa-sort-down "></span></span></a></th>
            <th><a href="/workbenches/#{workbench.id}?direction=desc&amp;sort=validity_period">Période de validité<span class="orderers"><span class="fa fa-sort-up "></span><span class="fa fa-sort-down "></span></span></a></th>
            <th><a href="/workbenches/#{workbench.id}?direction=desc&amp;sort=lines">Lignes<span class="orderers"><span class="fa fa-sort-up "></span><span class="fa fa-sort-down "></span></span></a></th>
            <th><a href="/workbenches/#{workbench.id}?direction=desc&amp;sort=created_at">Créé le<span class="orderers"><span class="fa fa-sort-up "></span><span class="fa fa-sort-down "></span></span></a></th>
            <th><a href="/workbenches/#{workbench.id}?direction=desc&amp;sort=updated_at">Edité le<span class="orderers"><span class="fa fa-sort-up "></span><span class="fa fa-sort-down "></span></span></a></th>
            <th><a href="/workbenches/#{workbench.id}?direction=desc&amp;sort=merged_at">Finalisé le<span class="orderers"><span class="fa fa-sort-up "></span><span class="fa fa-sort-down "></span></span></a></th>
            <th></th>
        </tr>
    </thead>
    <tbody>
        <tr class="referential referential-#{referential.id}">
            <td>
                <div class="checkbox"><input type="checkbox" name="#{referential.id}" id="#{referential.id}" value="#{referential.id}" /><label for="#{referential.id}"></label></div>
            </td>
            <td title="Voir" class="name"><a href="/referentials/#{referential.id}">#{referential.name}</a></td>
            <td>
                <div class='td-block'><span class='sb sb-lg sb-preparing'></span><span>En préparation</span></div>
            </td>
            <td>#{referential.organisation.name}</td>
            <td>-</td>
            <td>#{referential.lines.count}</td>
            <td>#{I18n.localize(referential.created_at)}</td>
            <td>#{I18n.localize(referential.updated_at)}</td>
            <td></td>
            <td class="actions">
                <div class="btn-group">
                    <div class="btn dropdown-toggle" data-toggle="dropdown"><span class="fa fa-cog"></span></div>
                    <div class="dropdown-menu">
                        <ul class="primary">
                            <li class=""><a href="/referentials/#{referential.id}"><span class='mr-xs fa fa-eye'></span>Consulter</a></li>
                            <li class=""><a href="/referentials/#{referential.id}/edit"><span class='mr-xs fa fa-pencil-alt'></span>Editer ce jeu de données</a></li>
                        </ul>
                        <ul class="other">
                            <li class=""><a href="/referentials/#{referential.id}/time_tables">Calendriers</a></li>
                            <li class=""><a href="/workbenches/#{workbench.id}/referentials/new?from=#{referential.id}">Dupliquer</a></li>
                            <li class=""><a href="/workbenches/#{workbench.id}/control_list_runs/new?referential_id=#{referential.id}">Contrôler</a></li>
                            <li class=""><a rel="nofollow" data-method="put" href="/referentials/#{referential.id}/archive">Archiver</a></li>
                        </ul>
                        <ul class="footer">
                            <li class=" delete-action"><a data-confirm="Etes vous sûr de vouloir supprimer ce jeu de données ?" rel="nofollow" data-method="delete" href="/referentials/#{referential.id}"><span class='mr-xs fa fa-trash text-danger'></span>Supprimer ce jeu de données</a></li>
                        </ul>
                    </div>
                </div>
            </td>
        </tr>
    </tbody>
</table>
      HTML

      html_str = helper.table_builder_2(
        referentials,
        [
          TableBuilderHelper::Column.new(
            key: :name,
            attribute: 'name',
            link_to: lambda do |referential|
              referential_path(referential)
            end
          ),
          TableBuilderHelper::Column.new(
            key: :status,
            attribute: Proc.new do |w|
              if w.referential_read_only?
                ("<div class='td-block'><span class='fa fa-archive'></span><span>Conservé</span></div>").html_safe
              else
                ("<div class='td-block'><span class='sb sb-lg sb-preparing'></span><span>En préparation</span></div>").html_safe
              end
            end
          ),
          TableBuilderHelper::Column.new(
            key: :organisation,
            attribute: Proc.new {|w| w.organisation.name}
          ),
          TableBuilderHelper::Column.new(
            key: :validity_period,
            attribute: Proc.new do |w|
              if w.validity_period.nil?
                '-'
              else
                t(
                  'validity_range',
                  debut: l(w.try(:validity_period).try(:begin)),
                  end: l(w.try(:validity_period).try(:end))
                )
              end
            end
          ),
          TableBuilderHelper::Column.new(
            key: :lines,
            attribute: Proc.new {|w| w.lines.count}
          ),
          TableBuilderHelper::Column.new(
            key: :created_at,
            attribute: Proc.new {|w| l(w.created_at)}
          ),
          TableBuilderHelper::Column.new(
            key: :updated_at,
            attribute: Proc.new {|w| l(w.updated_at)}
          ),
          TableBuilderHelper::Column.new(
            key: :merged_at,
            attribute: ''
          )
        ],
        selectable: true,
        action: :index,
        cls: 'table has-filter has-search'
      )

      beautified_html = HtmlBeautifier.beautify(html_str, indent: '    ')

      expect(beautified_html).to eq(expected.chomp)
    end

    it "can set a column as non-sortable" do
      company = create(:company)
      line_referential = company.line_referential
      workbench = company.line_provider.workbench
      referential = build_stubbed(
        :referential,
        line_referential: line_referential
      )

      user_context = UserContext.new(
        build_stubbed(
          :user,
          organisation: referential.organisation,
          permissions: [
            'referentials.create',
            'referentials.edit',
            'referentials.destroy'
          ]
        ),
        referential: referential
      )
      allow(helper).to receive(:pundit_user).and_return(user_context)
      allow(helper).to receive(:current_user).and_return(user_context.user)
      allow(helper).to receive(:current_referential)
        .and_return(line_referential)

      companies = [company]

      allow(companies).to receive(:model).and_return(Chouette::Company)

      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(
        controller: 'companies',
        action: 'index',
        workbench_id: workbench.id
      ))

      companies = CompanyDecorator.decorate(
        companies,
        context: { workbench: workbench }
      )
      stub_policy_scope(company)

      expected = <<-HTML
<table class="table has-search">
    <thead>
        <tr>
            <th>ID Codif</th>
            <th><a href="/workbenches/#{workbench.id}/line_referential/companies?direction=desc&amp;sort=name">Nom<span class="orderers"><span class="fa fa-sort-up "></span><span class="fa fa-sort-down "></span></span></a></th>
            <th><a href="/workbenches/#{workbench.id}/line_referential/companies?direction=desc&amp;sort=default_contact_phone">Numéro de téléphone<span class="orderers"><span class="fa fa-sort-up "></span><span class="fa fa-sort-down "></span></span></a></th>
            <th><a href="/workbenches/#{workbench.id}/line_referential/companies?direction=desc&amp;sort=default_contact_email">Email<span class="orderers"><span class="fa fa-sort-up "></span><span class="fa fa-sort-down "></span></span></a></th>
            <th><a href="/workbenches/#{workbench.id}/line_referential/companies?direction=desc&amp;sort=default_contact_url">Page web associée<span class="orderers"><span class="fa fa-sort-up "></span><span class="fa fa-sort-down "></span></span></a></th>
            <th></th>
        </tr>
    </thead>
    <tbody>
        <tr class="company company-#{company.id}">
            <td>#{company.get_objectid.local_id}</td>
            <td title="Voir" class="name"><a href="/workbenches/#{workbench.id}/line_referential/companies/#{company.id}">#{company.name}</a></td>
            <td class="default_contact_phone">#{company.default_contact_phone}</td>
            <td class="default_contact_email">#{company.default_contact_email}</td>
            <td class="default_contact_url">#{company.default_contact_url}</td>
            <td class="actions">
                <div class="btn-group">
                    <div class="btn dropdown-toggle" data-toggle="dropdown"><span class="fa fa-cog"></span></div>
                    <div class="dropdown-menu">
                        <ul class="primary">
                            <li class=""><a href="/workbenches/#{workbench.id}/line_referential/companies/#{company.id}"><span class='mr-xs fa fa-eye'></span>Consulter</a></li>
                        </ul>
                    </div>
                </div>
            </td>
        </tr>
    </tbody>
</table>
      HTML

      html_str = helper.table_builder_2(
        companies,
        [
          TableBuilderHelper::Column.new(
            name: 'ID Codif',
            attribute: Proc.new { |n| n.try(:get_objectid).try(:local_id) },
            sortable: false
          ),
          TableBuilderHelper::Column.new(
            key: :name,
            attribute: 'name',
            link_to: lambda do |c|
              workbench_line_referential_company_path(workbench, c)
            end
          ),
          TableBuilderHelper::Column.new(
            key: :default_contact_phone,
            attribute: 'default_contact_phone'
          ),
          TableBuilderHelper::Column.new(
            key: :default_contact_email,
            attribute: 'default_contact_email'
          ),
          TableBuilderHelper::Column.new(
            key: :default_contact_url,
            attribute: 'default_contact_url'
          ),
        ],
        links: [:show, :edit, :delete],
        cls: 'table has-search'
      )

      beautified_html = HtmlBeautifier.beautify(html_str, indent: '    ')
      expect(beautified_html).to eq(expected.chomp)
    end

    it "can set all columns as non-sortable" do
      company = create(:company)
      line_referential = company.line_referential
      workbench = company.line_provider.workbench
      referential = build_stubbed(
        :referential,
        line_referential: line_referential
      )

      user_context = UserContext.new(
        build_stubbed(
          :user,
          organisation: referential.organisation,
          permissions: [
            'referentials.create',
            'referentials.edit',
            'referentials.destroy'
          ]
        ),
        referential: referential
      )
      allow(helper).to receive(:pundit_user).and_return(user_context)
      allow(helper).to receive(:current_user).and_return(user_context.user)
      allow(helper).to receive(:current_referential)
        .and_return(line_referential)

      companies = [company]

      allow(companies).to receive(:model).and_return(Chouette::Company)

      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(
        controller: 'companies',
        action: 'index',
        workbench_id: workbench.id
      ))

      companies = CompanyDecorator.decorate(
        companies,
        context: { workbench: workbench }
      )
      stub_policy_scope(company)

      expected = <<-HTML
<table class="table has-search">
    <thead>
        <tr>
            <th>ID Codif</th>
            <th>Nom</th>
            <th>Numéro de téléphone</th>
            <th>Email</th>
            <th>Page web associée</th>
            <th></th>
        </tr>
    </thead>
    <tbody>
        <tr class="company company-#{company.id}">
            <td>#{company.get_objectid.local_id}</td>
            <td title="Voir" class="name"><a href="/workbenches/#{workbench.id}/line_referential/companies/#{company.id}">#{company.name}</a></td>
            <td class="default_contact_phone">#{company.default_contact_phone}</td>
            <td class="default_contact_email">#{company.default_contact_email}</td>
            <td class="default_contact_url">#{company.default_contact_url}</td>
            <td class="actions">
                <div class="btn-group">
                    <div class="btn dropdown-toggle" data-toggle="dropdown"><span class="fa fa-cog"></span></div>
                    <div class="dropdown-menu">
                        <ul class="primary">
                            <li class=""><a href="/workbenches/#{workbench.id}/line_referential/companies/#{company.id}"><span class='mr-xs fa fa-eye'></span>Consulter</a></li>
                        </ul>
                    </div>
                </div>
            </td>
        </tr>
    </tbody>
</table>
      HTML

      html_str = helper.table_builder_2(
        companies,
        [
          TableBuilderHelper::Column.new(
            name: 'ID Codif',
            attribute: Proc.new { |n| n.try(:get_objectid).try(:local_id) }
          ),
          TableBuilderHelper::Column.new(
            key: :name,
            attribute: 'name',
            link_to: lambda do |c|
              workbench_line_referential_company_path(workbench, c)
            end
          ),
          TableBuilderHelper::Column.new(
            key: :default_contact_phone,
            attribute: 'default_contact_phone'
          ),
          TableBuilderHelper::Column.new(
            key: :default_contact_email,
            attribute: 'default_contact_email'
          ),
          TableBuilderHelper::Column.new(
            key: :default_contact_url,
            attribute: 'default_contact_url'
          ),
        ],
        sortable: false,
        cls: 'table has-search'
      )

      beautified_html = HtmlBeautifier.beautify(html_str, indent: '    ')

      expect(beautified_html).to eq(expected.chomp)
    end

    context "on a single row" do
      let(:referential){ build_stubbed :workbench_referential }
      let(:other_referential){ build_stubbed :workbench_referential }
      let(:user_context){
        UserContext.new(
          build_stubbed(
            :user,
            organisation: referential.organisation,
            permissions: [
              'referentials.create',
              'referentials.update',
              'referentials.destroy',
            ]
          ),
          referential: referential
        )
      }
      let(:columns){
        [
          TableBuilderHelper::Column.new(
            key: :name,
            attribute: 'name'
          ),
        ]
      }
      let(:item){ referential.decorate }
      let(:other_item){ other_referential.decorate }
      let(:selectable){ false }
      let(:links){ [:show] }
      let(:overhead){ [] }
      let(:model_name){ "referential" }
      let(:other_tr){ helper.send(:tr, other_item, columns, selectable, links, overhead, model_name) }
      let(:items){ [item, other_item] }

      before(:each){
        allow(helper).to receive(:pundit_user).and_return(user_context)
        allow(helper).to receive(:current_user).and_return(user_context.user)
        allow(helper).to receive(:mutual_workbench).and_return(referential.workbench)
      }

      context "with a condition" do
        let(:columns){
          [
            TableBuilderHelper::Column.new(
              key: :name,
              attribute: 'name',
              if: condition
            ),
          ]
        }

        context "when the condition is true" do
          let(:condition){ ->(obj){true} }
          it "should show the value" do
            items.each do |i|
              tr = helper.send(:tr, i, columns, selectable, links, overhead, model_name, :index)
              expect(tr).to include(i.name)
            end
          end
        end

        context "when the condition depends on the object" do
          let(:condition){ ->(obj){ obj == referential } }
          it "should show the value accordingly" do
            tr = helper.send(:tr, item, columns, selectable, links, overhead, model_name, :index)
            expect(tr).to include(referential.name)
            tr = helper.send(:tr, other_item, columns, selectable, links, overhead, model_name, :index)
            expect(tr).to_not include(other_referential.name)
          end
        end

        context "when the condition is false" do
          let(:condition){ ->(obj){false} }
          it "should not show the value" do
            items.each do |i|
              tr = helper.send(:tr, i, columns, selectable, links, overhead, model_name, :index)
              expect(tr).to_not include(i.name)
            end
          end
        end

      end

      context "with all rows non-selectable" do
        let(:selectable){ false }
        it "sets all rows as non selectable" do
          items.each do |i|
            tr = helper.send(:tr, i, columns, selectable, links, overhead, model_name, :index)
            klass = "#{TableBuilderHelper.item_row_class_name([referential])}-#{i.id}"
            selector = "tr.#{klass} [type=checkbox]"
            expect(tr).to_not have_selector selector
          end
        end
      end

      context "with all rows selectable" do
        let(:selectable){ true }
        it "adds a checkbox in all rows" do
          items.each do |i|
            tr = helper.send(:tr, i, columns, selectable, links, overhead, model_name, :index)
            klass = "#{TableBuilderHelper.item_row_class_name([referential])}-#{i.id}"
            selector = "tr.#{klass} [type=checkbox]"
            expect(tr).to have_selector selector
          end
        end
      end

      context "with THIS row non selectable" do
        let(:selectable){ ->(i){ i.id != item.id } }
        it "adds a checkbox in all rows" do
          items.each do |i|
            tr = helper.send(:tr, i, columns, selectable, links, overhead, model_name, :index)
            klass = "#{TableBuilderHelper.item_row_class_name([referential])}-#{i.id}"
            selector = "tr.#{klass} [type=checkbox]"
            expect(tr).to have_selector selector
          end
        end
        it "disables this rows checkbox" do
          tr = helper.send(:tr, item, columns, selectable, links, overhead, model_name, :index)
          klass = "#{TableBuilderHelper.item_row_class_name([referential])}-#{item.id}"
          selector = "tr.#{klass} [type=checkbox][disabled]"
          expect(tr).to have_selector selector
        end
      end
    end
  end
end
